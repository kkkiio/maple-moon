///| Contains information about an equip
pub struct EquipData {
  category : String
  gender : Int
  req_stats : Map[@maple_stat.Id, Int]
  incr_stats : Map[@maple_stat.EquipStatId, Int]
  eq_slot : @slot.Id
}

///| Load an equip from the game files.
pub fn EquipData::parse_item_data(
  item_data : @item.ItemData
) -> EquipData raise {
  let id = item_data.item_id
  let gender = @item.get_item_gender(id)
  // let cash = info["cash"].get_bool!()
  // let trade_block = info["tradeBlock"].get_bool!()
  // let slots = info["tuc"].get_int!()
  let info = item_data.get_info()
  let req_stats = req_stats_keys
    .iter()
    .map(fn(it) {
      let (key, stat) = it
      (
        stat,
        info
        .get(key)
        .bind(fn(it) { it.as_number() })
        .map_or(0, fn(it) { it.to_int() }),
      )
    })
    |> Map::from_iter()
  let def_stats = def_stats_keys
    .iter()
    .filter_map(fn(it) {
      let (key, stat) = it
      info
      .get(key)
      .bind(fn(it) { it.as_number() })
      .map(fn(it) { (stat, it.to_int()) })
    })
    |> Map::from_iter()
  let non_weapon_types = 15
  let weapon_offset = non_weapon_types + 15
  let weapon_types = 20
  let index = id / 10000 - 100
  let eq_slot = if index < non_weapon_types {
    // let types = [
    //   "HAT", "FACE ACCESSORY", "EYE ACCESSORY", "EARRINGS", "TOP", "OVERALL", "BOTTOM",
    //   "SHOES", "GLOVES", "SHIELD", "CAPE", "RING", "PENDANT", "BELT", "MEDAL",
    // ]
    equipslots[index]
  } else if index >= weapon_offset && index < weapon_offset + weapon_types {
    // let types = [
    //   "ONE-HANDED SWORD", "ONE-HANDED AXE", "ONE-HANDED MACE", "DAGGER", "", "",
    //   "", "WAND", "STAFF", "", "TWO-HANDED SWORD", "TWO-HANDED AXE", "TWO-HANDED MACE",
    //   "SPEAR", "POLEARM", "BOW", "CROSSBOW", "CLAW", "KNUCKLE", "GUN",
    // ]
    // let weaponindex = index - weapon_offset
    @slot.Id::WEAPON
  } else {
    // "CASH"
    @slot.Id::NONE
  }
  guard @item.parse_equip_category(id) is Some(category) else {
    fail("failed to parse equip category for item id \{id}")
  }
  { category, gender, req_stats, incr_stats: def_stats, eq_slot }
}

///|
let equipslots : FixedArray[@slot.Id] = [
  @slot.Id::HAT,
  @slot.Id::FACE,
  @slot.Id::EYE_ACC,
  @slot.Id::EARACC,
  @slot.Id::TOP,
  @slot.Id::TOP,
  @slot.Id::BOTTOM,
  @slot.Id::SHOES,
  @slot.Id::GLOVES,
  @slot.Id::SHIELD,
  @slot.Id::CAPE,
  @slot.Id::RING1,
  @slot.Id::PENDANT1,
  @slot.Id::BELT,
  @slot.Id::MEDAL,
]

///|
pub fn get_defstat(self : EquipData, stat : @maple_stat.EquipStatId) -> Int {
  self.incr_stats.get(stat).or(0)
}

///|
pub fn get_eqslot(self : EquipData) -> @slot.Id {
  self.eq_slot
}

///|
pub fn get_category(self : EquipData) -> String {
  self.category
}

///|
pub fn get_reqstat(self : EquipData, stat : @maple_stat.Id) -> Int {
  self.req_stats.get(stat).or(0)
}

///|
pub fn get_gender(self : EquipData) -> Int {
  self.gender
}

///|
let req_stats_keys : Array[(String, @maple_stat.Id)] = [
  ("reqLevel", @maple_stat.Id::LEVEL),
  ("reqJob", @maple_stat.Id::JOB),
  ("reqSTR", @maple_stat.Id::STR),
  ("reqDEX", @maple_stat.Id::DEX),
  ("reqINT", @maple_stat.Id::INT),
  ("reqLUK", @maple_stat.Id::LUK),
]

///|
let def_stats_keys : Array[(String, @maple_stat.EquipStatId)] = [
  ("incSTR", @maple_stat.EquipStatId::STR),
  ("incDEX", @maple_stat.EquipStatId::DEX),
  ("incINT", @maple_stat.EquipStatId::INT),
  ("incLUK", @maple_stat.EquipStatId::LUK),
  ("incPAD", @maple_stat.EquipStatId::WATK),
  ("incPDD", @maple_stat.EquipStatId::WDEF),
  ("incMAD", @maple_stat.EquipStatId::MAGIC),
  ("incMDD", @maple_stat.EquipStatId::MDEF),
  ("incMHP", @maple_stat.EquipStatId::HP),
  ("incMMP", @maple_stat.EquipStatId::MP),
  ("incACC", @maple_stat.EquipStatId::ACC),
  ("incEVA", @maple_stat.EquipStatId::AVOID),
  ("incHANDS", @maple_stat.EquipStatId::HANDS),
  ("incSPEED", @maple_stat.EquipStatId::SPEED),
  ("incJUMP", @maple_stat.EquipStatId::JUMP),
]
