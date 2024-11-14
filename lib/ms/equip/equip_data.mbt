/// Contains information about an equip
struct EquipData {
  category : String
  gender : Int
  req_stats : Map[@maple_stat.Id, Int]
  def_stats : Map[@stat.Id, Int]
  eq_slot : @slot.Id
}

/// Load an equip from the game files.
pub fn EquipData::from_item_data(item_data : @item.ItemData) -> EquipData! {
  let id = item_data.item_id
  let gender = @item.get_item_gender(id)
  // let cash = info["cash"].get_bool!()
  // let trade_block = info["tradeBlock"].get_bool!()
  // let slots = info["tuc"].get_int!()
  let info = item_data.get_info()
  let req_stats = req_stats_keys
    .iter()
    .map(
      fn(it) {
        let (key, stat) = it
        (
          stat,
          info[key]
          .bind(fn(it) { it.as_number() })
          .map_or(0, fn(it) { it.to_int() }),
        )
      },
    )
    |> Map::from_iter()
  let def_stats = def_stats_keys
    .iter()
    .map(
      fn(it) {
        let (key, stat) = it
        (
          stat,
          info[key]
          .bind(fn(it) { it.as_number() })
          .map_or(0, fn(it) { it.to_int() }),
        )
      },
    )
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
  let category = @item.get_eqcategory!(id)
  { category, gender, req_stats, def_stats, eq_slot }
}

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

pub fn get_defstat(self : EquipData, stat : @stat.Id) -> Int {
  self.def_stats.get(stat).or(0)
}

pub fn get_eqslot(self : EquipData) -> @slot.Id {
  self.eq_slot
}

pub fn get_category(self : EquipData) -> String {
  self.category
}

pub fn get_reqstat(self : EquipData, stat : @maple_stat.Id) -> Int {
  self.req_stats.get(stat).or(0)
}

pub fn get_gender(self : EquipData) -> Int {
  self.gender
}

let req_stats_keys : Array[(String, @maple_stat.Id)] = [
  ("reqLevel", @maple_stat.Id::LEVEL),
  ("reqJob", @maple_stat.Id::JOB),
  ("reqSTR", @maple_stat.Id::STR),
  ("reqDEX", @maple_stat.Id::DEX),
  ("reqINT", @maple_stat.Id::INT),
  ("reqLUK", @maple_stat.Id::LUK),
]

let def_stats_keys : Array[(String, @stat.Id)] = [
  ("incSTR", @stat.Id::STR),
  ("incDEX", @stat.Id::DEX),
  ("incINT", @stat.Id::INT),
  ("incLUK", @stat.Id::LUK),
  ("incPAD", @stat.Id::WATK),
  ("incPDD", @stat.Id::WDEF),
  ("incMAD", @stat.Id::MAGIC),
  ("incMDD", @stat.Id::MDEF),
  ("incMHP", @stat.Id::HP),
  ("incMMP", @stat.Id::MP),
  ("incACC", @stat.Id::ACC),
  ("incEVA", @stat.Id::AVOID),
  ("incHANDS", @stat.Id::HANDS),
  ("incSPEED", @stat.Id::SPEED),
  ("incJUMP", @stat.Id::JUMP),
]
