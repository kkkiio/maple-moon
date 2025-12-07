///|
pub(all) struct ChangeMapMessage {
  died : Bool
  target_id : Int
  target_p : String
  use_wheel : Bool
} derive(ToJson, FromJson)

///|
pub impl ClientMessage for ChangeMapMessage with type_code() {
  @net.ClientOpcode::CHANGE_MAP.int_value()
}

///|
pub(all) enum SetFieldMessage {
  ChangeMap(map_id~ : Int, portal_id~ : Int)
  SetField(
    stats~ : StatsEntry,
    inventory_entry~ : InventoryEntry,
    skills~ : Array[SkillEntry],
    cooldowns~ : @resource.EnumMap[Int, Int],
    quests~ : PlayerQuestLogInfo
  )
} derive(Show, ToJson, @json.FromJson)

///|
pub(all) struct StatsEntry {
  name : String
  female : Bool
  stats : @resource.EnumMap[@maple_stat.Id, Int]
  i64stats : @resource.EnumMap[@maple_stat.Id, Int64]
  map_id : Int
  portal_id : Int
} derive(Show, Default, ToJson, @json.FromJson)

///|
pub(all) struct InventoryEntry {
  meso : Int
  slot_maxs : @resource.EnumMap[InventoryType, Int]
  items : Array[InventoryItemEntry]
} derive(Show, Default, ToJson, @json.FromJson)

///|
pub(all) struct SkillEntry {
  skill_id : Int
  level : Int
  masterlevel : Int
  expiration : Int64
} derive(Show, ToJson, @json.FromJson)

///|
pub(all) struct PlayerQuestLogInfo {
  started : Array[(Int, String)]
  completed : Array[(Int, Int64)]
} derive(Show, Default, ToJson, @json.FromJson)

///|
pub(all) enum InventoryType {
  EQUIP = 1
  USE = 2
  SETUP = 3
  ETC = 4
  CASH = 5
  EQUIPPED = 6
} derive(Eq, Hash, Show, ToJson, @json.FromJson)

///|
pub fn InventoryType::int_value(self : InventoryType) -> Int = "%identity"

///|
pub fn InventoryType::by_item_id(item_id : Int) -> InventoryType? {
  let prefix = item_id / 1000000
  match prefix {
    1 => InventoryType::EQUIP |> Some
    2 => InventoryType::USE |> Some
    3 => InventoryType::SETUP |> Some
    4 => InventoryType::ETC |> Some
    5 => InventoryType::CASH |> Some
    _ => None
  }
}

///|
pub fn InventoryType::by_value(value : Int) -> InventoryType? {
  match value {
    -1 => InventoryType::EQUIPPED |> Some
    1 => InventoryType::EQUIP |> Some
    2 => InventoryType::USE |> Some
    3 => InventoryType::SETUP |> Some
    4 => InventoryType::ETC |> Some
    5 => InventoryType::CASH |> Some
    _ => None
  }
}

///|
pub(all) enum InventoryItemEntry {
  Equip(
    invtype~ : InventoryType,
    slot~ : Int,
    id~ : Int,
    cash~ : Bool,
    expire~ : Int64,
    slots~ : Int,
    level~ : Int,
    stats~ : @resource.EnumMap[@maple_stat.EquipStatId, Int],
    owner~ : String,
    flag~ : Int,
    itemlevel~ : Int,
    itemexp~ : Int,
    vicious~ : Int
  )
  Pet(
    invtype~ : InventoryType,
    slot~ : Int,
    id~ : Int,
    cash~ : Bool,
    petname~ : String
  )
  Item(
    invtype~ : InventoryType,
    slot~ : Int,
    id~ : Int,
    cash~ : Bool,
    expire~ : Int64,
    count~ : Int,
    owner~ : String,
    flag~ : Int
  )
} derive(Show, ToJson, @json.FromJson)

///|
/// Tell the server which character was picked.
pub(all) struct SelectCharMessage {
  character_id : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for SelectCharMessage with type_code() {
  @net.ClientOpcode::SELECT_CHAR.int_value()
}
