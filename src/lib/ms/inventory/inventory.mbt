///|
enum Movement {
  MOVE_NONE
  MOVE_INTERNAL
  MOVE_UNEQUIP
  MOVE_EQUIP
} derive(Eq, Hash, Show, ToJson)

///|
pub fn Movement::int_value(self : Movement) -> Int {
  match self {
    Movement::MOVE_NONE => -1
    Movement::MOVE_INTERNAL => 0
    Movement::MOVE_UNEQUIP => 1
    Movement::MOVE_EQUIP => 2
  }
}

///|
enum ModificationMode {
  ADD(InventoryItemEntry)
  CHANGE_COUNT
  SWAP
  REMOVE
  ADD_COUNT
} derive(Show, ToJson)

///|
pub enum InventoryChangedKind {
  /// Item content in one inventory tab changed.
  ITEM
  /// Meso amount changed.
  MESO
  /// Inventory state was fully reset.
  RESET
} derive(Eq, Show)

///|
/// Minimal inventory change event used by downstream cache invalidation.
pub struct InventoryChangedEvent {
  /// Change category.
  kind : InventoryChangedKind
  /// Inventory tab if this is an item change.
  tab : TypeId?
  /// Slot index when known.
  slot : Int?
} derive(Eq, Show)

///|
/// Global inventory change event bus.
pub let inventory_changed_event_bus : @event.Events[InventoryChangedEvent] = @event.Events::new()

///|
fn parse_int_arg(args : Array[String], index : Int, default : Int) -> Int {
  guard index >= 0 && index < args.length() else { return default }
  @string.parse_int(args[index]) catch {
    _ => default
  }
}

///|
fn init {
  inventory_changed_event_bus.register_to_world(@ecs.require_current_world())
  @console.register_command("meso", fn(args) {
    let meso = parse_int_arg(args, 0, 0)
    @game_server.send(@server_proto.AdminCommandMessage::SetMeso(meso~))
    { "ok": true, "code": "OK", "message": "meso command sent", "args": args }
  })
  @console.register_command("item", fn(args) {
    let item_id = parse_int_arg(args, 0, 0)
    let quantity = parse_int_arg(args, 1, 1)
    @game_server.send(
      @server_proto.AdminCommandMessage::AddItem(item_id~, quantity~),
    )
    { "ok": true, "code": "OK", "message": "item command sent", "args": args }
  })
}

///|
/// Return the move type by value
pub fn Movement::from_int(value : Int) -> Movement raise @utils.UnknownEnum {
  match value {
    -1 => Movement::MOVE_NONE
    0 => Movement::MOVE_INTERNAL
    1 => Movement::MOVE_UNEQUIP
    2 => Movement::MOVE_EQUIP
    _ => raise @utils.UnknownEnum(value)
  }
}

///|
/// The player's inventory
struct Inventory {
  inventories : @utils.DefaultMap[TypeId, Map[SlotNo, SlotItem]]
  items : Map[Int, Item]
  equips : Map[Int, @equip_data.Equip]
  pets : Map[Int, @pet.Pet]
  mut running_uid : Int
  total_stats : @utils.DefaultMap[@maple_stat.EquipStatId, Int]
  type_slot_count_map : Map[TypeId, Int]
  mut meso : Int
  mut bullet_slot : Int
  item_listeners_map : Map[TypeId, Array[() -> Bool]] // TODO: fine-grained listeners
  meso_listeners : Array[(Int) -> Bool]
}

///|
pub struct SlotItem {
  unique_id : Int
  item_id : Int
  mut count : Int
  // cash : Bool
}

///|
pub fn Inventory::clear(self : Inventory) -> Unit {
  for _, inv in self.inventories.map {
    inv.clear()
  }
  self.items.clear()
  self.equips.clear()
  self.pets.clear()
  self.meso = 0
  self.total_stats.map.clear()
  inventory_changed_event_bus.send({ kind: RESET, tab: None, slot: None })
}

///|
pub fn Inventory::new() -> Inventory {
  {
    inventories: @utils.DefaultMap::new(fn() { Map::new() }),
    items: Map::new(),
    equips: Map::new(),
    pets: Map::new(),
    running_uid: 0,
    meso: 0,
    bullet_slot: 0,
    total_stats: @utils.DefaultMap::new(fn() { 0 }),
    type_slot_count_map: Map::from_array([
      (TypeId::EQUIP, 96),
      (TypeId::USE, 96),
      (TypeId::SETUP, 96),
      (TypeId::ETC, 96),
      (TypeId::CASH, 96),
      (TypeId::EQUIPPED, @equip_slot.Id::length()),
    ]),
    item_listeners_map: Map::new(),
    meso_listeners: Array::new(),
  }
}

///|
pub fn Inventory::apply_modify_inventory_message(
  self : Inventory,
  item_entry : @server_proto.InventoryItemEntry,
) -> Unit {
  match item_entry {
    Equip(invtype~, slot~, id~, cash=_, flag~, itemlevel~, vicious~, stats~, ..) => {
      if id <= 0 {
        self.remove_slot_entry(invtype, slot)
        self.trigger_item_listeners(invtype)
        return
      }
      let unique_id = self.running_uid
      self.running_uid += 1
      let slot_item : SlotItem = { unique_id, item_id: id, count: 1 }
      if slot > 0 {
        self.inventories[invtype][slot] = slot_item
      } else if slot < 0 {
        self.inventories[TypeId::EQUIPPED][-slot] = slot_item
      }
      self.equips[unique_id] = {
        item_id: id,
        stats: stats.0,
        expiration: 0,
        owner: "",
        flags: flag,
        slots: 7,
        level: 0,
        item_level: itemlevel,
        vicious,
        potential_rank: @equip_data.Potential::POT_NONE,
      }
      self.trigger_item_listeners(invtype)
      if slot < 0 {
        self.trigger_item_listeners(TypeId::EQUIPPED)
      }
    }
    Item(invtype~, slot~, id~, count~, ..) => {
      let unique_id = self.running_uid
      self.running_uid += 1
      let slot_item : SlotItem = { unique_id, item_id: id, count }
      self.inventories[invtype][slot] = slot_item
      self.trigger_item_listeners(invtype)
    }
    _ => ()
  }
}

///|
fn Inventory::remove_slot_entry(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
) -> Unit {
  if self.inventories[invtype].get(slot) is Some(slot_item) {
    self.inventories[invtype].remove(slot) |> ignore
    self.equips.remove(slot_item.unique_id)
    self.items.remove(slot_item.unique_id)
    self.pets.remove(slot_item.unique_id)
    inventory_changed_event_bus.send({
      kind: ITEM,
      tab: Some(invtype),
      slot: Some(slot),
    })
  }
}

///|
fn Inventory::trigger_item_listeners(self : Inventory, t : TypeId) -> Unit {
  inventory_changed_event_bus.send({ kind: ITEM, tab: Some(t), slot: None })
  match self.item_listeners_map.get(t) {
    Some(listeners) => {
      let survivors = Array::new()
      for callback in listeners {
        if callback() {
          survivors.push(callback)
        }
      }
      self.item_listeners_map.set(t, survivors)
    }
    None => ()
  }
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "inventory_logic_modify_inventory",
    @server_proto.Opcode::MODIFY_INVENTORY.int_value(),
    fn(message_json : Json) -> Unit raise {
      let message : @server_proto.ModifyInventoryMessage = @json.from_json(
        message_json,
      )
      inventory.val.apply_local_modify_inventory_message(message)
    },
  )
}

///|
pub fn Inventory::apply_local_modify_inventory_message(
  self : Inventory,
  message : @server_proto.ModifyInventoryMessage,
) -> Unit {
  @log.info("apply_local_modify_inventory_message before", data={
    "mods": message.mods.to_json(),
    "movement": message.movement.to_json(),
    "equip_1": self.get_item_id(TypeId::EQUIP, 1).to_json(),
    "equipped_11": self.get_item_id(TypeId::EQUIPPED, 11).to_json(),
  })
  for mod in message.mods {
    match mod.mode {
      @server_proto.ModifyInventoryMode::ADD =>
        match mod.item {
          Some(item) => self.apply_modify_inventory_message(item)
          None => ()
        }
      @server_proto.ModifyInventoryMode::CHANGE_COUNT =>
        self.modify(
          mod.t,
          mod.pos,
          ModificationMode::CHANGE_COUNT,
          mod.arg,
          Movement::MOVE_NONE,
        )
      @server_proto.ModifyInventoryMode::REMOVE =>
        self.modify(
          mod.t,
          mod.pos,
          ModificationMode::REMOVE,
          0,
          Movement::MOVE_INTERNAL,
        )
      @server_proto.ModifyInventoryMode::ADD_COUNT =>
        self.modify(
          mod.t,
          mod.pos,
          ModificationMode::ADD_COUNT,
          mod.arg,
          Movement::MOVE_NONE,
        )
      @server_proto.ModifyInventoryMode::SWAP => ()
    }
  }
  let movement = match message.movement {
    Some(v) => Movement::from_int(v) catch { _ => Movement::MOVE_INTERNAL }
    None => Movement::MOVE_INTERNAL
  }
  for mod in message.mods {
    match mod.mode {
      @server_proto.ModifyInventoryMode::SWAP =>
        self.modify(mod.t, mod.pos, ModificationMode::SWAP, mod.arg, movement)
      _ => ()
    }
  }
  @log.info("apply_local_modify_inventory_message after", data={
    "equip_1": self.get_item_id(TypeId::EQUIP, 1).to_json(),
    "equipped_11": self.get_item_id(TypeId::EQUIPPED, 11).to_json(),
  })
  match @player.get_player() {
    Some(player) => self.recalc_stats(player.character.get_weapontype())
    None => ()
  }
}

///|
/// Recalculate sums of equip stats
pub impl @legacy_types.Inventory for Inventory with recalc_stats(
  self : Inventory,
  weapontype : @weapon.Type,
) -> Unit {
  self.total_stats.map.clear()
  for _, slot in self.inventories[TypeId::EQUIPPED] {
    match self.equips.get(slot.unique_id) {
      Some(equip) =>
        for id, stat in equip.stats {
          self.total_stats.map.set(id, self.total_stats.op_get(id) + stat)
        }
      None => ()
    }
  }
  let mut prefix = 0
  match weapontype {
    @weapon.Type::BOW => prefix = 2060
    @weapon.Type::CROSSBOW => prefix = 2061
    @weapon.Type::CLAW => prefix = 2070
    @weapon.Type::GUN => prefix = 2330
    _ => prefix = 0
  }
  self.bullet_slot = 0
  if prefix != 0 {
    for slot_no, slot in self.inventories[TypeId::USE] {
      if slot.count != 0 && slot.item_id / 1000 == prefix {
        self.bullet_slot = slot_no.0
        break
      }
    }
  }

  // let bulletid = self.get_bulletid()
  // if (bulletid!=0) {
  //     self.total_stats[EquipStat::Id::WATK] += BulletData::get(bulletid).get_watk();
  // }
}

///|
pub fn Inventory::get_meso(self : Inventory) -> Int {
  self.meso
}

///|
/// Set the meso amount.
pub fn Inventory::set_meso(self : Inventory, meso : Int) -> Unit {
  self.meso = meso
  inventory_changed_event_bus.send({ kind: MESO, tab: None, slot: None })
  self.meso_listeners.retain(fn(listener) { listener(meso) })
}

///|
pub fn Inventory::set_slotmax(
  self : Inventory,
  type_id : TypeId,
  slotmax : Int,
) -> Unit {
  self.type_slot_count_map.set(type_id, slotmax)
}

///|
pub fn Inventory::add_item(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  cash : Bool,
  expiration : Int64,
  count : Int,
  owner : String,
  flags : Int,
) -> Unit {
  self.items.set(self.add_slot(invtype, slot, item_id, count, cash), {
    item_id,
    expiration,
    owner,
    flags,
  })
  self.notify_item_listeners(invtype)
}

///|
fn Inventory::add_slot(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  count : Int,
  _cash : Bool,
) -> Int {
  self.running_uid += 1
  let unique_id = self.running_uid
  self.inventories[invtype][slot] = { unique_id, item_id, count }
  unique_id
}

///|
pub fn Inventory::add_pet(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  cash : Bool,
  pet_name : String,
) -> Unit {
  self.pets.set(self.add_slot(invtype, slot, item_id, 1, cash), { pet_name, })
  self.notify_item_listeners(invtype)
}

///|
pub fn Inventory::add_equip(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  cash : Bool,
  expiration : Int64,
  slots : Int,
  level : Int,
  stats : Map[@maple_stat.EquipStatId, Int],
  owner : String,
  flags : Int,
  item_level : Int,
  _iexp : Int,
  vicious : Int,
) -> Unit {
  self.equips.set(self.add_slot(invtype, slot, item_id, 1, cash), {
    stats,
    item_id,
    expiration,
    owner,
    flags,
    slots,
    level,
    item_level,
    vicious,
    potential_rank: @equip_data.Potential::POT_NONE,
    // quality: @equip_data.get_quality(item_id, level > 0, stats),
  })
  self.notify_item_listeners(invtype)
}

///|
pub impl @legacy_types.Inventory for Inventory with get_stat(
  self : Inventory,
  stat : @maple_stat.EquipStatId,
) -> Int {
  self.total_stats[stat]
}

///|
pub impl @legacy_types.Inventory for Inventory with has_projectile(
  self : Inventory,
) -> Bool {
  self.bullet_slot > 0
}

///|
pub impl @legacy_types.Inventory for Inventory with get_bulletid(
  self : Inventory,
) -> Int {
  self.get_item_id(TypeId::USE, self.bullet_slot)
}

///|
pub fn Inventory::get_item_id(self : Inventory, t : TypeId, slot : Int) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.item_id }).unwrap_or(0)
}

///|
pub fn Inventory::get_slot_item_at(
  self : Inventory,
  t : TypeId,
  slot : Int,
) -> SlotItem? {
  self.inventories[t].get(slot)
}

///|
pub impl @legacy_types.Inventory for Inventory with get_bulletcount(
  self : Inventory,
) -> Int {
  self.get_item_count_at_slot(TypeId::USE, self.bullet_slot)
}

///|
pub fn Inventory::get_item_count_at_slot(
  self : Inventory,
  t : TypeId,
  slot : Int,
) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.count }).unwrap_or(0)
}

///|
pub fn Inventory::get_item_count(self : Inventory, item_id : Int) -> Int {
  // TODO: make a index for items
  // search in items
  for _, map in self.inventories.map {
    for _, slot in map {
      if slot.item_id == item_id {
        return slot.count
      }
    }
  } nobreak {
    0
  }
}

///|
pub fn Inventory::modify(
  self : Inventory,
  t : TypeId,
  slot : Int,
  mode : ModificationMode,
  arg : Int,
  mov : Movement,
) -> Unit {
  let mut notify_other_tab : TypeId? = None
  let (slot, t) = if slot < 0 { (-slot, TypeId::EQUIPPED) } else { (slot, t) }
  let arg = arg.abs()
  match mode {
    ModificationMode::CHANGE_COUNT => self.change_count(t, slot, arg)
    ModificationMode::ADD_COUNT => self.add_count(t, slot, arg)
    ModificationMode::SWAP =>
      match mov {
        Movement::MOVE_INTERNAL => self.swap(t, slot, t, arg)
        Movement::MOVE_UNEQUIP => {
          self.swap(TypeId::EQUIPPED, slot, TypeId::EQUIP, arg)
          notify_other_tab = Some(TypeId::EQUIP)
        }
        Movement::MOVE_EQUIP => {
          self.swap(TypeId::EQUIP, slot, TypeId::EQUIPPED, arg)
          notify_other_tab = Some(TypeId::EQUIPPED)
        }
        _ => ()
      }
    ModificationMode::REMOVE => self.remove(t, slot)
    ModificationMode::ADD(_) => ()
  }
  self.notify_item_listeners(t)
  match notify_other_tab {
    Some(other_tab) if other_tab != t => self.notify_item_listeners(other_tab)
    _ => ()
  }
}

///|
fn Inventory::notify_item_listeners(self : Inventory, t : TypeId) -> Unit {
  inventory_changed_event_bus.send({ kind: ITEM, tab: Some(t), slot: None })
  match self.item_listeners_map.get(t) {
    Some(listeners) => listeners.retain(fn(listener) { listener() })
    None => ()
  }
}

///|
fn Inventory::swap(
  self : Inventory,
  firsttype : TypeId,
  firstslot : Int,
  secondtype : TypeId,
  secondslot : Int,
) -> Unit {
  let first = self.inventories[firsttype].get(firstslot)
  let second = self.inventories[secondtype].get(secondslot)
  match second {
    Some(second) => self.inventories[firsttype][firstslot] = second
    None => self.remove(firsttype, firstslot)
  }
  match first {
    Some(first) => self.inventories[secondtype][secondslot] = first
    None => self.remove(secondtype, secondslot)
  }
}

///|
fn Inventory::remove(self : Inventory, t : TypeId, slot_id : Int) -> Unit {
  guard self.inventories[t].get(slot_id) is Some(slot) else { return }
  let unique_id = slot.unique_id
  self.inventories[t].remove(slot_id)
  match t {
    TypeId::EQUIPPED | TypeId::EQUIP => self.equips.remove(unique_id)
    TypeId::CASH => {
      self.items.remove(unique_id)
      self.pets.remove(unique_id)
    }
    _ => self.items.remove(unique_id)
  }
}

///|
fn Inventory::change_count(
  self : Inventory,
  t : TypeId,
  slot : Int,
  count : Int,
) -> Unit {
  match self.inventories[t].get(slot) {
    Some(slot) => slot.count = count
    None => ()
  }
}

///|
fn Inventory::add_count(
  self : Inventory,
  t : TypeId,
  slot : Int,
  count : Int,
) -> Unit {
  match self.inventories[t].get(slot) {
    Some(slot_item) => slot_item.count += count
    None => ()
  }
}

///|
pub fn Inventory::get_bulletslot(self : Inventory) -> Int {
  self.bullet_slot
}

///|
pub fn Inventory::get_slotmax(self : Inventory, t : TypeId) -> Int {
  self.type_slot_count_map.get(t).unwrap_or(0)
}

///|
/// Determines the appropriate equipment slot for a given piece of clothing.
/// 
/// If the clothing is a ring, it checks for available ring slots and returns the first unoccupied slot. 
/// If all ring slots are occupied, it defaults to RING1.
/// For non-ring equipment, it returns the equipment's default slot.
pub fn find_equip_slot(
  inv : Inventory,
  cloth : @equip_data.EquipData,
) -> @equip_slot.Id {
  let eqslot = cloth.get_eqslot()
  guard eqslot is @equip_slot.Id::RING1 else { return eqslot }
  [@equip_slot.Id::RING2, @equip_slot.Id::RING3, @equip_slot.Id::RING4]
  .iter()
  .find_first(fn(slot) { !inv.has_equipped(slot) })
  .unwrap_or(@equip_slot.Id::RING1)
}

///|
pub fn Inventory::has_equipped(self : Inventory, slot : @equip_slot.Id) -> Bool {
  self.inventories[TypeId::EQUIPPED].contains(slot.int_value())
}

///|
pub fn Inventory::listen_item_changes(
  self : Inventory,
  t : TypeId,
  listener : () -> Bool,
) -> Unit {
  self.item_listeners_map.get_or_init(t, fn() { Array::new() }).push(listener)
}

///|
pub fn Inventory::listen_meso_changes(
  self : Inventory,
  listener : (Int) -> Bool,
) -> Unit {
  self.meso_listeners.push(listener)
}

///|
pub fn Inventory::find_item(
  self : Inventory,
  t : TypeId,
  itemid : Int,
) -> SlotNo? {
  for slot_no, slot in self.inventories[t] {
    if slot.item_id == itemid {
      return Some(slot_no)
    }
  }
  None
}

///|
pub fn Inventory::use_item(self : Inventory, itemid : Int) -> Unit {
  guard TypeId::by_item_id(itemid) is Some(type_) else { return }
  guard self.find_item(type_, itemid) is Some(slot_no) else { return }
  if type_ is TypeId::USE {
    @game_server.send(@server_proto.UseItemMessage::{
      slot_no: slot_no.0,
      item_id: itemid,
    })
  }
}

///|
pub let inventory : Ref[Inventory] = Ref::new(Inventory::new())

///|
pub fn use_item_at_slot(type_id : TypeId, slot_no : Int) -> String? {
  let self = inventory.val
  @log.info("use_item_at_slot type=\{type_id} slot=\{slot_no}")
  match type_id {
    EQUIP => {
      guard self.get_slot_item_at(type_id, slot_no) is Some(item) else {
        return Some("no item at slot \{slot_no} of \{type_id}")
      }
      @item_use_events.push_intent(
        @item_use_events.ItemUseIntent::TryEquip(
          type_id~,
          slot_no~,
          item_id=item.item_id,
        ),
      )
      None
    }
    USE => {
      let item_id = self.get_item_id(type_id, slot_no)
      if item_id <= 0 {
        return Some("not found item id at slot \{slot_no} of \{type_id}")
      }
      @item_use_events.push_intent(
        @item_use_events.ItemUseIntent::TryUse(type_id~, slot_no~, item_id~),
      )
      None
    }
    _ => Some("not supported kind \{type_id}")
  }
}

///|
/// Slot number. starts from 1
pub struct SlotNo(Int) derive(Eq, Hash, Show, ToJson)
