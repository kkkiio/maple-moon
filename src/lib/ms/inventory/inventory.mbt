///|
enum Movement {
  MOVE_NONE
  MOVE_INTERNAL
  MOVE_UNEQUIP
  MOVE_EQUIP
} derive(Eq, Hash, Show, ToJson)

///|
pub fn int_value(self : Movement) -> Int {
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

///| Return the move type by value
pub fn Movement::from_int(value : Int) -> Movement!@utils.UnknownEnum {
  match value {
    -1 => Movement::MOVE_NONE
    0 => Movement::MOVE_INTERNAL
    1 => Movement::MOVE_UNEQUIP
    2 => Movement::MOVE_EQUIP
    _ => raise @utils.UnknownEnum(value)
  }
}

///| The player's inventory
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
  network : @net.Network
}

///|
pub struct SlotItem {
  unique_id : Int
  item_id : Int
  mut count : Int
  // cash : Bool
}

///|
pub fn Inventory::new(network : @net.Network) -> Inventory {
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
      (TypeId::EQUIPPED, @equip_slot.Id::length()),
    ]),
    item_listeners_map: Map::new(),
    meso_listeners: Array::new(),
    network,
  }
}

///| Recalculate sums of equip stats
pub impl @player.Inventory for Inventory with recalc_stats(
  self : Inventory,
  weapontype : @weapon.Type
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
    for _, slot in self.inventories[TypeId::USE] {
      if slot.count != 0 && slot.item_id / 1000 == prefix {
        self.bullet_slot = slot.unique_id
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
pub fn get_meso(self : Inventory) -> Int {
  self.meso
}

///| Set the meso amount.
pub fn set_meso(self : Inventory, meso : Int) -> Unit {
  self.meso = meso
  self.meso_listeners.retain(fn(listener) { listener(meso) })
}

///|
pub fn set_slotmax(self : Inventory, type_id : TypeId, slotmax : Int) -> Unit {
  self.type_slot_count_map.set(type_id, slotmax)
}

///|
pub fn add_item(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  cash : Bool,
  expiration : Int64,
  count : Int,
  owner : String,
  flags : Int
) -> Unit {
  self.items.set(self.add_slot(invtype, slot, item_id, count, cash), {
    item_id,
    expiration,
    owner,
    flags,
  })
}

///|
fn add_slot(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  count : Int,
  _cash : Bool
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
  pet_name : String
) -> Unit {
  self.pets.set(self.add_slot(invtype, slot, item_id, 1, cash), { pet_name, })
}

///|
pub fn add_equip(
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
  vicious : Int
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
}

///|
pub impl @player.Inventory for Inventory with get_stat(
  self : Inventory,
  stat : @maple_stat.EquipStatId
) -> Int {
  self.total_stats[stat]
}

///|
pub impl @player.Inventory for Inventory with has_projectile(self : Inventory) -> Bool {
  self.bullet_slot > 0
}

///|
pub impl @player.Inventory for Inventory with get_bulletid(self : Inventory) -> Int {
  self.get_item_id(TypeId::USE, self.bullet_slot)
}

///|
pub fn get_item_id(self : Inventory, t : TypeId, slot : Int) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.item_id }).or(0)
}

///|
pub fn get_slot_item_at(self : Inventory, t : TypeId, slot : Int) -> SlotItem? {
  self.inventories[t].get(slot)
}

///|
pub impl @player.Inventory for Inventory with get_bulletcount(self : Inventory) -> Int {
  self.get_item_count(TypeId::USE, self.bullet_slot)
}

///|
pub fn Inventory::get_item_count(
  self : Inventory,
  t : TypeId,
  slot : Int
) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.count }).or(0)
}

///|
pub fn modify(
  self : Inventory,
  t : TypeId,
  slot : Int,
  mode : ModificationMode,
  arg : Int,
  mov : Movement
) -> Unit {
  let (slot, t) = if slot < 0 { (-slot, TypeId::EQUIPPED) } else { (slot, t) }
  let arg = arg.abs()
  match mode {
    ModificationMode::CHANGE_COUNT => self.change_count(t, slot, arg)
    ModificationMode::SWAP =>
      match mov {
        Movement::MOVE_INTERNAL => self.swap(t, slot, t, arg)
        Movement::MOVE_UNEQUIP =>
          self.swap(TypeId::EQUIPPED, slot, TypeId::EQUIP, arg)
        Movement::MOVE_EQUIP =>
          self.swap(TypeId::EQUIP, slot, TypeId::EQUIPPED, arg)
        _ => ()
      }
    ModificationMode::REMOVE => self.remove(t, slot)
    _ => ...
  }
  match self.item_listeners_map.get(t) {
    Some(listeners) => listeners.retain(fn(listener) { listener() })
    None => ()
  }
}

///|
fn swap(
  self : Inventory,
  firsttype : TypeId,
  firstslot : Int,
  secondtype : TypeId,
  secondslot : Int
) -> Unit {
  let first = self.inventories[firsttype][firstslot]
  let second = self.inventories[secondtype][secondslot]
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
fn remove(self : Inventory, t : TypeId, slot_id : Int) -> Unit {
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
fn change_count(self : Inventory, t : TypeId, slot : Int, count : Int) -> Unit {
  match self.inventories[t].get(slot) {
    Some(slot) => slot.count = count
    None => ()
  }
}

///|
pub fn get_bulletslot(self : Inventory) -> Int {
  self.bullet_slot
}

///|
pub fn get_slotmax(self : Inventory, t : TypeId) -> Int {
  self.type_slot_count_map.get(t).or(0)
}

///| Determines the appropriate equipment slot for a given piece of clothing.
/// 
/// If the clothing is a ring, it checks for available ring slots and returns the first unoccupied slot. 
/// If all ring slots are occupied, it defaults to RING1.
/// For non-ring equipment, it returns the equipment's default slot.
pub fn find_equip_slot(
  inv : Inventory,
  cloth : @equip_data.EquipData
) -> @equip_slot.Id {
  let eqslot = cloth.get_eqslot()
  guard eqslot is @equip_slot.Id::RING1 else { return eqslot }
  [@equip_slot.Id::RING2, @equip_slot.Id::RING3, @equip_slot.Id::RING4]
  .iter()
  .find_first(fn(slot) { not(inv.has_equipped(slot)) })
  .or(@equip_slot.Id::RING1)
}

///|
pub fn has_equipped(self : Inventory, slot : @equip_slot.Id) -> Bool {
  self.inventories[TypeId::EQUIPPED].contains(slot.int_value())
}

///|
pub fn listen_item_changes(
  self : Inventory,
  t : TypeId,
  listener : () -> Bool
) -> Unit {
  self.item_listeners_map.get_or_init(t, fn() { Array::new() }).push(listener)
}

///|
pub fn listen_meso_changes(self : Inventory, listener : (Int) -> Bool) -> Unit {
  self.meso_listeners.push(listener)
}

///|
fn Inventory::find_item(self : Inventory, t : TypeId, itemid : Int) -> SlotNo? {
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
    self.network.send_message(UseItemMessage::new(slot_no._, itemid))
  }
}

///| Slot number. starts from 1
pub type SlotNo Int derive(Eq, Hash, Show, ToJson)
