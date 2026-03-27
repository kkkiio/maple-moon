///|
using @server_proto {
  type ChangeStatsMesoMessage,
  type CharacterListEntry,
  type CharacterListMessage,
  trait ClientMessage,
  type CreateCharacterResultMessage,
  trait ServerMessage,
  type ChangeMapMessage,
  type DropLootMessage,
  type MoveItemMessage,
  type ModifyInventoryMessage,
  type ModifyInventoryMod,
  type ModifyInventoryMode,
  type OpenNpcShopMessage,
  type PickupItemMessage,
  type ShowStatusMesoGainMessage,
  type MoveMonsterMessage,
  type SetFieldMessage,
  type QuestActionMessage,
  type SelectCharMessage,
  type MobSpawnControllerMessage,
  type NpcSpawnControllerMessage,
  type StatsEntry,
  type UseItemMessage,
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
}

///|
using @resource {get_mapx_loader}

///|
pub let default_rand_seed : Ref[Bytes] = Ref::new(
  b"0123456789abcdef0123456789abcdef",
)

///|
/// A local server implementation for playing the game offline.
///
/// Although there is a open-source server implementation `Cosmic`,
/// it is burdensome to implement the full client features, so we implement a local server here to play the game offline.
///
/// We can use the built-in resource loader in `@resource` package to load the resources and implement the server logic here.
struct LocalServer {
  client_message_queue : @queue.Queue[(Int, Json)]
  server_message_queue : @queue.Queue[(Int, Json)]
  client_message_handler_map : Map[Int, (Json) -> Unit raise]
  server_message_handlers_map : Map[Int, Array[(String, (Json) -> Unit raise)]]
  mut last_map_id : Int
  mut last_portal_id : Int
  mut last_object_id : Int
  mut spawn_batch_id : Int
  mut map_transfer_ready : Bool
  mut player_meso : Int
  mut current_character_id : Int
  mut character_revision : Int
  character_roster : Array[CharacterListEntry]
  player_items : Map[InventoryType, Map[Int, @server_proto.InventoryItemEntry]]
  slot_max_by_tab : Map[InventoryType, Int]
  mobs : Map[Int, ServerMob]
  drops : Map[Int, DropLootMessage]
  pending_mob_spawns : Array[PendingMobSpawn]
  pending_npc_spawns : Array[NpcSpawnControllerMessage]
  mut active_shop : OpenNpcShopMessage?
  npc_id_by_oid : Map[Int, Int]
  mut npc_shop_db : NpcShopDatabase?
  db : &DB
  mut drop_db : MobDropDatabase?
  mut global_drop_db : MobDropDatabase?
  drop_rng : @random.Rand
  mut quest_defs : Map[Int, QuestDefinition]
  started_quests : Map[Int, String]
  mut completed_quests : Map[Int, Int64]
}

///|
priv struct ServerMob {
  id : Int
  x : Int
  y : Int
  mut hp : Int
  max_hp : Int
}

///|
priv struct PendingMobSpawn {
  msg : MobSpawnControllerMessage
  max_hp : Int
}

///|
pub fn LocalServer::new(
  db~ : &DB,
  drop_rng? : @random.Rand = @random.Rand::chacha8(seed=default_rand_seed.val),
) -> LocalServer {
  {
    client_message_queue: @queue.new(),
    server_message_queue: @queue.new(),
    client_message_handler_map: {},
    server_message_handlers_map: {},
    last_map_id: 100000000,
    last_portal_id: 0,
    last_object_id: 100000,
    spawn_batch_id: 0,
    map_transfer_ready: false,
    player_meso: 0,
    current_character_id: 1,
    character_revision: 0,
    character_roster: [],
    player_items: {
      let m : Map[InventoryType, Map[Int, @server_proto.InventoryItemEntry]] = Map::new()
      m.set(InventoryType::EQUIP, Map::new())
      m.set(InventoryType::EQUIPPED, Map::new())
      m.set(InventoryType::USE, Map::new())
      m.set(InventoryType::SETUP, Map::new())
      m.set(InventoryType::ETC, Map::new())
      m.set(InventoryType::CASH, Map::new())
      m
    },
    slot_max_by_tab: {
      let m : Map[InventoryType, Int] = Map::new()
      m.set(InventoryType::EQUIP, 96)
      m.set(InventoryType::USE, 96)
      m.set(InventoryType::SETUP, 96)
      m.set(InventoryType::ETC, 96)
      m.set(InventoryType::CASH, 96)
      m
    },
    mobs: Map::new(),
    drops: Map::new(),
    pending_mob_spawns: Array::new(),
    pending_npc_spawns: Array::new(),
    active_shop: None,
    npc_id_by_oid: Map::new(),
    npc_shop_db: None,
    db,
    drop_db: None,
    global_drop_db: None,
    drop_rng,
    quest_defs: {},
    started_quests: {},
    completed_quests: make_default_completed_quests(),
  }
}

///|
pub fn init_server(server : LocalServer) -> Unit {
  server.init_routes()
  server.init_quest_runtime()
  // 加载掉落数据库
  server.load_drop_databases()
  // 加载 NPC 商店数据库
  server.load_npc_shop_database()
}

///|
pub fn LocalServer::init_routes(self : LocalServer) -> Unit {
  self.client_message_handler_map[@server_proto.ClientOpcode::SELECT_CHAR.int_value()] = v => {
    self.on_select_char(v)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::CHAR_LIST_REQUEST.int_value()] = _ => {
    self.on_character_list_request()
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::CREATE_CHAR.int_value()] = json => {
    self.on_create_char(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::CHANGE_MAP.int_value()] = v => {
    self.on_change_map(v)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::PLAYER_MAP_TRANSFER.int_value()] = _ => {
    self.map_transfer_ready = true
    self.flush_pending_mob_spawns()
    self.flush_pending_npc_spawns()
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::CLOSE_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::RANGED_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::MAGIC_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::MOVE_MONSTER.int_value()] = json => {
    let msg : MoveMonsterMessage = @json.from_json(json)
    match self.mobs.get(msg.oid) {
      Some(mob) =>
        self.mobs.set(msg.oid, { ..mob, x: msg.start_pos.x, y: msg.start_pos.y })
      None => ()
    }
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::PICKUP_ITEM.int_value()] = json => {
    self.on_pickup_item(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::USE_ITEM.int_value()] = json => {
    self.on_use_item(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::MOVE_ITEM.int_value()] = json => {
    self.on_move_item(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::TALK_TO_NPC.int_value()] = json => {
    self.on_talk_to_npc(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::NPC_TALK_MORE.int_value()] = _ => {
    ()
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::NPC_SHOP_ACTION.int_value()] = json => {
    self.on_npc_shop_action(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::QUEST_ACTION.int_value()] = json => {
    self.on_quest_action(json)
  }
  self.client_message_handler_map[@server_proto.ClientOpcode::ADMIN_COMMAND.int_value()] = json => {
    self.on_admin_command(json)
  }
}

///|
priv struct CreateCharRequest {
  name : String
  _job : Int
  face : Int
  hair : Int
  hairc : Int
  skin : Int
  top : Int
  bot : Int
  shoes : Int
  weapon : Int
  female : Bool
} derive(FromJson)

///|
fn default_character_look() -> @char_look.LookEntry {
  {
    female: false,
    skin: 0,
    faceid: 20000,
    hairid: 30030,
    equips: Map::from_array([
      (@slot.Id::TOP.int_value(), 1040002),
      (@slot.Id::BOTTOM.int_value(), 1060002),
      (@slot.Id::SHOES.int_value(), 1072001),
      (@slot.Id::WEAPON.int_value(), 1302000),
    ]),
    maskedequips: {},
    petids: [],
  }
}

///|
fn default_character_entry() -> CharacterListEntry {
  { character_id: 1, name: "kkkiio", look: default_character_look() }
}

///|
async fn make_equipped_inventory_entry(
  slot_id : @slot.Id,
  item_id : Int,
) -> InventoryItemEntry {
  new_inventory_item_entry(
    InventoryType::EQUIPPED,
    slot_id.int_value(),
    item_id,
    1,
  )
}

///|
async fn LocalServer::apply_character_look_to_inventory(
  self : LocalServer,
  look : @char_look.LookEntry,
) -> Unit {
  self.reset_player_inventory_state()
  guard self.player_items.get(InventoryType::EQUIPPED) is Some(equipped_items) else {
    return
  }
  let item_ids = [
    (@slot.Id::TOP, look.equips.get(@slot.Id::TOP.int_value())),
    (@slot.Id::BOTTOM, look.equips.get(@slot.Id::BOTTOM.int_value())),
    (@slot.Id::SHOES, look.equips.get(@slot.Id::SHOES.int_value())),
    (@slot.Id::WEAPON, look.equips.get(@slot.Id::WEAPON.int_value())),
  ]
  for item in item_ids {
    let (slot_id, item_id) = item
    match item_id {
      Some(id) =>
        equipped_items.set(
          slot_id.int_value(),
          make_equipped_inventory_entry(slot_id, id),
        )
      None => ()
    }
  }
}

///|
async fn LocalServer::init_character_storage(
  self : LocalServer,
  entry : CharacterListEntry,
) -> Unit {
  self.current_character_id = entry.character_id
  self.last_map_id = 100000000
  self.last_portal_id = 0
  self.player_meso = 0
  self.apply_character_look_to_inventory(entry.look)
  self.save_character(entry.character_id)
  self.save_character_roster()
}

///|
fn LocalServer::find_character_entry(
  self : LocalServer,
  character_id : Int,
) -> CharacterListEntry? {
  for entry in self.character_roster {
    if entry.character_id == character_id {
      return Some(entry)
    }
  }
  None
}

///|
fn LocalServer::on_character_list_request(self : LocalServer) -> Unit {
  @io_service.execute_background(async fn() {
    if self.character_roster.is_empty() {
      ignore(self.load_character_roster())
    }
    self.send_server_message(CharacterListMessage::{
      characters: self.character_roster.copy(),
    })
  })
}

///|
fn LocalServer::on_create_char(self : LocalServer, json : Json) -> Unit raise {
  let request : CreateCharRequest = @json.from_json(json)
  @io_service.execute_background(
    async fn() {
      if self.character_roster.is_empty() {
        let entry = default_character_entry()
        self.character_roster.push(entry)
        self.init_character_storage(entry)
      }
      let normalized_hair_id = request.hair + request.hairc
      for entry in self.character_roster {
        if entry.name == request.name {
          self.send_server_message(CreateCharacterResultMessage::{
            success: false,
            character: None,
            error: Some("Character name already exists"),
          })
          return
        }
      }
      let mut next_id = 1
      for entry in self.character_roster {
        if entry.character_id >= next_id {
          next_id = entry.character_id + 1
        }
      }
      let entry : CharacterListEntry = {
        character_id: next_id,
        name: request.name,
        look: {
          female: request.female,
          skin: request.skin,
          faceid: request.face,
          hairid: normalized_hair_id,
          equips: Map::from_array([
            (@slot.Id::TOP.int_value(), request.top),
            (@slot.Id::BOTTOM.int_value(), request.bot),
            (@slot.Id::SHOES.int_value(), request.shoes),
            (@slot.Id::WEAPON.int_value(), request.weapon),
          ]),
          maskedequips: {},
          petids: [],
        },
      }
      self.character_roster.push(entry)
      self.init_character_storage(entry)
      self.send_server_message(CreateCharacterResultMessage::{
        success: true,
        character: Some(entry),
        error: None,
      })
    },
    on_error=fn(err) {
      @log.error("failed to create character", data={ "error": err })
    },
  )
}

///|
/// send client message to the server
#callsite(autofill(loc))
pub fn[T : ClientMessage] LocalServer::send_client_message(
  self : LocalServer,
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(
    log_level,
    "send_client_message",
    data={ "message": @log.JsonValue(json) },
    loc~,
  )
  self.client_message_queue.push((type_code, json))
}

///|
fn LocalServer::on_mob_damage(self : LocalServer, json : Json) -> Unit raise {
  let msg : @server_proto.MobDamageMessage = @json.from_json(json)
  guard self.mobs.get(msg.oid) is Some(mob) else { return }
  mob.hp -= msg.damage
  if mob.hp <= 0 {
    mob.hp = 0
    self.send_server_message(@server_proto.KillMobMessage::{
      oid: msg.oid,
      animation: 1,
    })
    // 生成掉落
    self.spawn_drops_for_mob(mob)
    self.mobs.remove(msg.oid)
  } else {
    let percent = (mob.hp.to_double() / mob.max_hp.to_double() * 100.0).to_int()
    self.send_server_message(@server_proto.MobHpMessage::{
      oid: msg.oid,
      percent,
    })
  }
}

///|
/// 为怪物生成掉落
/// 
/// WORKAROUND: skip equip items before we implement the equip data preloading.
fn LocalServer::spawn_drops_for_mob(
  self : LocalServer,
  mob : ServerMob,
) -> Unit {
  let active_quest_ids : Map[Int, Unit] = {}
  for quest_id, _ in self.started_quests {
    active_quest_ids.set(quest_id, ())
  }
  let (messages, next_oid) = calculate_mob_drops(
    mob.id,
    mob.x,
    mob.y,
    self.last_object_id,
    self.drop_db,
    self.global_drop_db,
    self.drop_rng,
    active_quest_ids~,
  )
  for msg in messages {
    if not(msg.meso) &&
      InventoryType::by_item_id(msg.item_id) == Some(InventoryType::EQUIP) {
      continue
    }
    self.drops.set(msg.oid, msg)
    self.send_server_message(msg)
  }
  self.last_object_id = next_oid
}

///|
fn LocalServer::on_pickup_item(self : LocalServer, json : Json) -> Unit raise {
  let msg : PickupItemMessage = @json.from_json(json)
  @io_service.execute_background(
    async fn() {
      guard self.drops.get(msg.oid) is Some(drop) else { return }
      if drop.meso {
        let gain = drop.item_id
        self.player_meso += gain
        self.save_character_core_snapshot()
        self.send_server_message(ChangeStatsMesoMessage::{
          meso: self.player_meso,
        })
        self.send_server_message(ShowStatusMesoGainMessage::{ gain, })
        self.drops.remove(msg.oid) |> ignore
        self.send_server_message(@server_proto.RemoveLootMessage::{
          mode: 2,
          oid: msg.oid,
          cid: Some(1),
        })
        return
      }
      guard self.apply_pickup_item(drop.item_id) else { return }
      self.save_character_inventory_snapshot()
      self.drops.remove(msg.oid) |> ignore
      self.send_server_message(@server_proto.RemoveLootMessage::{
        mode: 2,
        oid: msg.oid,
        cid: Some(1),
      })
    },
    on_error=fn(err) {
      @log.error("failed to pick up item", data={ "error": err, "oid": msg.oid })
    },
  )
}

///|
fn LocalServer::on_use_item(self : LocalServer, json : Json) -> Unit raise {
  let msg : UseItemMessage = @json.from_json(json)
  guard self.player_items.get(InventoryType::USE) is Some(use_items) else {
    return
  }
  guard use_items.get(msg.slot_no) is Some(item_entry) else { return }
  guard item_entry
    is InventoryItemEntry::Item(
      id=item_id,
      count=old_count,
      cash=c,
      expire=e,
      owner=o,
      flag=f,
      invtype=i,
      slot=it_slot
    ) else {
    return
  }
  guard item_id == msg.item_id && old_count > 0 else { return }
  let remain = old_count - 1
  if remain > 0 {
    use_items.set(
      msg.slot_no,
      InventoryItemEntry::Item(
        id=item_id,
        count=remain,
        cash=c,
        expire=e,
        owner=o,
        flag=f,
        invtype=i,
        slot=it_slot,
      ),
    )
  } else {
    use_items.remove(msg.slot_no) |> ignore
  }
  let mod = if remain > 0 {
    modify_change_count(InventoryType::USE, msg.slot_no, remain)
  } else {
    modify_remove(InventoryType::USE, msg.slot_no)
  }
  self.send_modify_inventory([mod], None)
  self.save_character_inventory_snapshot()
}

///|
fn LocalServer::on_move_item(self : LocalServer, json : Json) -> Unit raise {
  let msg : MoveItemMessage = @json.from_json(json)
  if msg.invtype != InventoryType::EQUIP {
    return
  }
  if msg.slot > 0 && msg.action < 0 {
    self.on_equip_item(msg.slot, -msg.action)
    return
  }
  if msg.slot < 0 && msg.action > 0 {
    self.on_unequip_item(-msg.slot, msg.action)
    return
  }
}

///|
fn set_item_entry_slot(
  entry : InventoryItemEntry,
  new_invtype : InventoryType,
  new_slot : Int,
) -> InventoryItemEntry {
  match entry {
    Equip(
      id~,
      cash~,
      expire~,
      slots~,
      level~,
      stats~,
      owner~,
      flag~,
      itemlevel~,
      itemexp~,
      vicious~,
      ..
    ) =>
      Equip(
        invtype=new_invtype,
        slot=new_slot,
        id~,
        cash~,
        expire~,
        slots~,
        level~,
        stats~,
        owner~,
        flag~,
        itemlevel~,
        itemexp~,
        vicious~,
      )
    Item(id~, cash~, expire~, count~, owner~, flag~, ..) =>
      Item(
        invtype=new_invtype,
        slot=new_slot,
        id~,
        cash~,
        expire~,
        count~,
        owner~,
        flag~,
      )
    Pet(id~, cash~, petname~, ..) =>
      Pet(invtype=new_invtype, slot=new_slot, id~, cash~, petname~)
  }
}

///|
fn modify_add(
  t : InventoryType,
  pos : Int,
  item : InventoryItemEntry,
) -> ModifyInventoryMod {
  { mode: ModifyInventoryMode::ADD, t, pos, arg: 0, item: Some(item) }
}

///|
fn modify_change_count(
  t : InventoryType,
  pos : Int,
  count : Int,
) -> ModifyInventoryMod {
  { mode: ModifyInventoryMode::CHANGE_COUNT, t, pos, arg: count, item: None }
}

///|
fn modify_remove(t : InventoryType, pos : Int) -> ModifyInventoryMod {
  { mode: ModifyInventoryMode::REMOVE, t, pos, arg: 0, item: None }
}

///|
fn modify_swap(t : InventoryType, pos : Int, arg : Int) -> ModifyInventoryMod {
  { mode: ModifyInventoryMode::SWAP, t, pos, arg, item: None }
}

///|
fn LocalServer::send_modify_inventory(
  self : LocalServer,
  mods : Array[ModifyInventoryMod],
  movement : Int?,
) -> Unit {
  self.send_server_message(ModifyInventoryMessage::{ mods, movement })
}

///|
fn LocalServer::on_equip_item(
  self : LocalServer,
  from_slot : Int,
  equipped_slot : Int,
) -> Unit {
  guard self.player_items.get(InventoryType::EQUIP) is Some(equip_items) else {
    return
  }
  guard self.player_items.get(InventoryType::EQUIPPED) is Some(equipped_items) else {
    return
  }
  guard equip_items.get(from_slot) is Some(equip_entry) else { return }
  @log.debug("local_server on_equip_item before", data={
    "from_slot": from_slot,
    "equipped_slot": equipped_slot,
    "equip_has_from": equip_items.contains(from_slot),
    "equipped_has_to": equipped_items.contains(equipped_slot),
  })
  match equipped_items.get(equipped_slot) {
    Some(equipped_entry) =>
      equip_items.set(
        from_slot,
        set_item_entry_slot(equipped_entry, InventoryType::EQUIP, from_slot),
      )
    None => equip_items.remove(from_slot) |> ignore
  }
  let new_equipped = set_item_entry_slot(
    equip_entry,
    InventoryType::EQUIPPED,
    equipped_slot,
  )
  equipped_items.set(equipped_slot, new_equipped)
  @log.debug("local_server on_equip_item after", data={
    "from_slot": from_slot,
    "equipped_slot": equipped_slot,
    "equip_has_from": equip_items.contains(from_slot),
    "equipped_has_to": equipped_items.contains(equipped_slot),
  })
  self.send_modify_inventory(
    [modify_swap(InventoryType::EQUIP, from_slot, -equipped_slot)],
    Some(2),
  )
  self.save_character_inventory_snapshot()
}

///|
fn LocalServer::on_unequip_item(
  self : LocalServer,
  equipped_slot : Int,
  to_slot : Int,
) -> Unit {
  guard self.player_items.get(InventoryType::EQUIP) is Some(equip_items) else {
    return
  }
  guard self.player_items.get(InventoryType::EQUIPPED) is Some(equipped_items) else {
    return
  }
  guard not(equip_items.contains(to_slot)) else { return }
  guard equipped_items.get(equipped_slot) is Some(equipped_entry) else {
    return
  }
  equipped_items.remove(equipped_slot) |> ignore
  let new_unequipped = set_item_entry_slot(
    equipped_entry,
    InventoryType::EQUIP,
    to_slot,
  )
  equip_items.set(to_slot, new_unequipped)
  self.send_modify_inventory(
    [modify_swap(InventoryType::EQUIP, -equipped_slot, to_slot)],
    Some(1),
  )
  self.save_character_inventory_snapshot()
}

///|
async fn new_inventory_item_entry(
  invtype : InventoryType,
  slot : Int,
  item_id : Int,
  count : Int,
) -> InventoryItemEntry {
  if invtype == InventoryType::EQUIP || invtype == InventoryType::EQUIPPED {
    let item_data = @item.ItemData::load_item_data(item_id) catch {
      err =>
        @log.fatal("failed to load item data for new equip", data={
          "item_id": item_id,
          "error": err.to_string(),
        })
    }
    let equip_data = @data.EquipData::parse_item_data(item_data) catch {
      err =>
        @log.fatal("failed to parse equip data for new equip", data={
          "item_id": item_id,
          "error": err.to_string(),
        })
    }
    let stats = Map::new()
    for stat_id in @maple_stat.all_equip_stats {
      let value = equip_data.get_defstat(stat_id)
      if value != 0 {
        stats.set(stat_id, value)
      }
    }
    InventoryItemEntry::Equip(
      invtype~,
      slot~,
      id=item_id,
      cash=false,
      expire=0,
      slots=7,
      level=0,
      stats=@resource.EnumMap(stats),
      owner="",
      flag=0,
      itemlevel=0,
      itemexp=0,
      vicious=0,
    )
  } else {
    InventoryItemEntry::Item(
      invtype~,
      slot~,
      id=item_id,
      cash=false,
      expire=0,
      count~,
      owner="",
      flag=0,
    )
  }
}

///|
async fn LocalServer::apply_pickup_item(
  self : LocalServer,
  item_id : Int,
) -> Bool {
  guard InventoryType::by_item_id(item_id) is Some(invtype) else {
    return false
  }
  guard self.player_items.get(invtype) is Some(tab_items) else { return false }
  let stackable = invtype != InventoryType::EQUIP
  if stackable {
    for slot, it in tab_items {
      guard it
        is InventoryItemEntry::Item(
          id=existing_item_id,
          count=existing_count,
          cash=c,
          expire=e,
          owner=o,
          flag=f,
          invtype=i,
          slot=it_slot
        ) else {
        continue
      }
      if existing_item_id == item_id {
        let next_count = existing_count + 1
        let updated_item = InventoryItemEntry::Item(
          id=item_id,
          count=next_count,
          cash=c,
          expire=e,
          owner=o,
          flag=f,
          invtype=i,
          slot=it_slot,
        )
        tab_items.set(slot, updated_item)
        self.send_modify_inventory(
          [modify_change_count(invtype, it_slot, next_count)],
          None,
        )
        return true
      }
    }
  }
  guard find_next_empty_slot(
      tab_items,
      self.slot_max_by_tab.get(invtype).unwrap_or(0),
    )
    is Some(slot) else {
    return false
  }
  let new_item = new_inventory_item_entry(invtype, slot, item_id, 1)
  tab_items.set(slot, new_item)
  self.send_modify_inventory([modify_add(invtype, slot, new_item)], None)
  true
}

///|
fn find_next_empty_slot(
  items : Map[Int, InventoryItemEntry],
  slot_max : Int,
) -> Int? {
  for slot in 1..<=slot_max {
    if not(items.contains(slot)) {
      return Some(slot)
    }
  }
  None
}

///|
fn LocalServer::reset_player_inventory_state(self : LocalServer) -> Unit {
  self.player_meso = 0
  for _, items in self.player_items {
    items.clear()
  }
  self.set_default_quest_state()
}

///|
fn LocalServer::save_character_core_snapshot(self : LocalServer) -> Unit {
  @io_service.execute_background(
    async fn() { self.save_character_core(self.current_character_id) },
    on_error=fn(err) {
      @log.error("failed to save character core snapshot", data={ "error": err })
    },
  )
}

///|
fn LocalServer::save_character_inventory_snapshot(self : LocalServer) -> Unit {
  @io_service.execute_background(
    async fn() { self.save_character_inventory(self.current_character_id) },
    on_error=fn(err) {
      @log.error("failed to save character inventory snapshot", data={
        "error": err,
      })
    },
  )
}

///|
fn LocalServer::save_character_quest_snapshot(self : LocalServer) -> Unit {
  @io_service.execute_background(
    async fn() {
      let revision = self.bump_character_revision()
      self.save_character_quest_data(self.current_character_id, revision)
      self.save_character_meta(self.current_character_id, revision, "quest")
    },
    on_error=fn(err) {
      @log.error("failed to save character quest snapshot", data={
        "error": err.to_string(),
      })
    },
  )
}

///|
fn LocalServer::bump_character_revision(self : LocalServer) -> Int {
  self.character_revision += 1
  self.character_revision
}

///|
fn LocalServer::append_inventory_entries(
  self : LocalServer,
  items : Array[InventoryItemEntry],
) -> Unit {
  for _invtype, tab_items in self.player_items {
    for _slot, item in tab_items {
      items.push(item)
    }
  }
}

///|
fn LocalServer::spawn_mobs_for_map(self : LocalServer, map_id : Int) -> Unit {
  self.spawn_batch_id += 1
  let batch_id = self.spawn_batch_id
  self.map_transfer_ready = false
  self.mobs.clear()
  self.drops.clear()
  self.pending_mob_spawns.clear()
  self.pending_npc_spawns.clear()
  self.active_shop = None
  self.npc_id_by_oid.clear()
  @io_service.execute_background(async fn() {
    let loader = get_mapx_loader()
    let prefix = (map_id / 100000000).to_string()
    let strid = @utils.stoi_left_pad0(map_id, 9)
    let path = ["Map\{prefix}", "\{strid}.img"]
    let node_res = loader.load_resource(path)
    guard node_res is { "life": Object(life_map), .. } else { return }
    for _, entity in life_map {
      if self.spawn_batch_id != batch_id {
        return
      }
      match entity {
        {
          "type": String("m"),
          "id": String(id_str),
          "x": Number(x, ..),
          "y": Number(y, ..),
          "f": Number(f, ..),
          "fh": Number(fh, ..),
          ..
        } => {
          let monster_id = @strconv.parse_int(id_str)
          self.last_object_id += 1
          let spawn_msg = MobSpawnControllerMessage::{
            oid: self.last_object_id,
            id: monster_id,
            mode: 1, // Passive Control
            x: x.to_int(),
            y: y.to_int(),
            stance: f.to_int(),
            fh: fh.to_int(),
            team: -1,
          }
          let mob_loader = @resource.get_mob_loader()
          let mob_strid = @utils.stoi_left_pad0(monster_id, 7)
          let mob_path = ["\{mob_strid}.img"]
          let mob_node = mob_loader.load_resource(mob_path)
          guard mob_node is { "info": { "maxHP": Number(max_hp, ..), .. }, .. } else {
            continue
          }
          self.pending_mob_spawns.push({
            msg: spawn_msg,
            max_hp: max_hp.to_int(),
          })
        }
        {
          "type": String("n"),
          "id": String(id_str),
          "x": Number(x, ..),
          "y": Number(y, ..),
          "f": Number(f, ..),
          "fh": Number(fh, ..),
          ..
        } => {
          self.last_object_id += 1
          let npc_id = @strconv.parse_int(id_str)
          self.pending_npc_spawns.push(NpcSpawnControllerMessage::{
            mode: 1,
            oid: self.last_object_id,
            id: npc_id,
            x: x.to_int(),
            y: y.to_int(),
            flip: f.to_int() != 0,
            fh: fh.to_int(),
          })
          self.npc_id_by_oid.set(self.last_object_id, npc_id)
        }
        _ => ()
      }
    }
    if self.map_transfer_ready && self.spawn_batch_id == batch_id {
      self.flush_pending_mob_spawns()
      self.flush_pending_npc_spawns()
    }
  })
}

///|
fn LocalServer::flush_pending_mob_spawns(self : LocalServer) -> Unit {
  for pending in self.pending_mob_spawns {
    self.send_server_message(pending.msg)
    let server_mob = ServerMob::{
      id: pending.msg.id,
      x: pending.msg.x,
      y: pending.msg.y,
      hp: pending.max_hp,
      max_hp: pending.max_hp,
    }
    self.mobs.set(pending.msg.oid, server_mob)
  }
  self.pending_mob_spawns.clear()
}

///|
fn LocalServer::flush_pending_npc_spawns(self : LocalServer) -> Unit {
  for msg in self.pending_npc_spawns {
    self.send_server_message(msg)
  }
  self.pending_npc_spawns.clear()
}

///|
#callsite(autofill(loc))
fn[T : ServerMessage] LocalServer::send_server_message(
  self : LocalServer,
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(
    log_level,
    "send_server_message",
    data={ "type_code": @log.HexInt(type_code), "json": @log.JsonValue(json) },
    loc~,
  )
  self.server_message_queue.push((type_code, json))
}

///|
pub fn LocalServer::add_server_message_handler(
  self : LocalServer,
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  self.server_message_handlers_map
  .get_or_init(type_code, fn() { Array::new() })
  .push((name, handler))
}

///|
pub fn server_system(server : LocalServer) -> Unit {
  while server.server_message_queue.pop() is Some((type_code, json)) {
    @log.debug("receive server message", data={
      "type_code": @log.HexInt(type_code),
      "json": @log.JsonValue(json),
    })
    guard server.server_message_handlers_map.get(type_code) is Some(handlers) else {
      continue
    }
    for handler in handlers {
      (handler.1)(json) catch {
        err =>
          @log.error("Error handling server message", data={
            "error": err.to_string(),
            "name": handler.0,
          })
      }
    }
  }
  while server.client_message_queue.pop() is Some((type_code, json)) {
    guard server.client_message_handler_map.get(type_code) is Some(handler) else {
      @log.debug("Missing client message handler", data={
        "type_code": @log.HexInt(type_code),
        "json": @log.JsonValue(json),
      })
      return
    }
    handler(json) catch {
      err => abort("Error handling client message: \{err.to_string()}")
    }
  }
}

///|
/// 加载怪物掉落数据库
fn LocalServer::load_drop_databases(self : LocalServer) -> Unit {
  let tsv_loader = @resource.get_csv_loader()
  // 加载怪物特定掉落
  @io_service.execute_background(async fn() {
    let text : String = tsv_loader.load_text("/assets/data/mob_drops.tsv")
    self.drop_db = Some(MobDropDatabase::from_tsv(text))
    @log.info("Loaded mob_drops.tsv", data={})
  })
  // 加载全局掉落
  @io_service.execute_background(async fn() {
    let text : String = tsv_loader.load_text(
      "/assets/data/drop_data_global.tsv",
    )
    self.global_drop_db = Some(MobDropDatabase::from_tsv(text))
    @log.info("Loaded drop_data_global.tsv", data={})
  })
}
