/// Contains information about an equip
struct EquipData {
  item_data : @item.ItemData
  req_stats : Map[@MapleStat.Id, Int]
  def_stats : Map[@stat.Id, Int]
  type_ : String
  eq_slot : @slot.Id
  slots : Int
  cash : Bool
  trade_block : Bool
}

/// Load an equip from the game files.
fn EquipData::load(id : Int) -> EquipData! {
  let item_data = @item.ItemData::get!(id)
  let strid = "0" + id.to_string()
  let category = item_data.category
  let src = @resource.character_loader().load_res(
    [category, strid + ".img", "info"],
  )
  let cash = src["cash"].get_bool!()
  let trade_block = src["tradeBlock"].get_bool!()
  let slots = src["tuc"].get_int!()
  let req_stats : Map[@MapleStat.Id, Int] = Map::new()
  req_stats[@MapleStat.Id::LEVEL] = src["reqLevel"].get_int!()
  req_stats[@MapleStat.Id::JOB] = src["reqJob"].get_int!()
  req_stats[@MapleStat.Id::STR] = src["reqSTR"].get_int!()
  req_stats[@MapleStat.Id::DEX] = src["reqDEX"].get_int!()
  req_stats[@MapleStat.Id::INT] = src["reqINT"].get_int!()
  req_stats[@MapleStat.Id::LUK] = src["reqLUK"].get_int!()
  let def_stats : Map[@stat.Id, Int] = Map::new()
  def_stats[@stat.Id::STR] = src["incSTR"].get_int!()
  def_stats[@stat.Id::DEX] = src["incDEX"].get_int!()
  def_stats[@stat.Id::INT] = src["incINT"].get_int!()
  def_stats[@stat.Id::LUK] = src["incLUK"].get_int!()
  def_stats[@stat.Id::WATK] = src["incPAD"].get_int!()
  def_stats[@stat.Id::WDEF] = src["incPDD"].get_int!()
  def_stats[@stat.Id::MAGIC] = src["incMAD"].get_int!()
  def_stats[@stat.Id::MDEF] = src["incMDD"].get_int!()
  def_stats[@stat.Id::HP] = src["incMHP"].get_int!()
  def_stats[@stat.Id::MP] = src["incMMP"].get_int!()
  def_stats[@stat.Id::ACC] = src["incACC"].get_int!()
  def_stats[@stat.Id::AVOID] = src["incEVA"].get_int!()
  def_stats[@stat.Id::HANDS] = src["incHANDS"].get_int!()
  def_stats[@stat.Id::SPEED] = src["incSPEED"].get_int!()
  def_stats[@stat.Id::JUMP] = src["incJUMP"].get_int!()
  let non_weapon_types = 15
  let weapon_offset = non_weapon_types + 15
  let weapon_types = 20
  let index = id / 10000 - 100
  let (type_, eq_slot) = if index < non_weapon_types {
    let types = [
      "HAT", "FACE ACCESSORY", "EYE ACCESSORY", "EARRINGS", "TOP", "OVERALL", "BOTTOM",
      "SHOES", "GLOVES", "SHIELD", "CAPE", "RING", "PENDANT", "BELT", "MEDAL",
    ]
    (types[index], equipslots[index])
  } else if index >= weapon_offset && index < weapon_offset + weapon_types {
    let types = [
      "ONE-HANDED SWORD", "ONE-HANDED AXE", "ONE-HANDED MACE", "DAGGER", "", "",
      "", "WAND", "STAFF", "", "TWO-HANDED SWORD", "TWO-HANDED AXE", "TWO-HANDED MACE",
      "SPEAR", "POLEARM", "BOW", "CROSSBOW", "CLAW", "KNUCKLE", "GUN",
    ]
    let weaponindex = index - weapon_offset
    (types[weaponindex], @slot.Id::WEAPON)
  } else {
    ("CASH", @slot.Id::NONE)
  }
  { item_data, req_stats, def_stats, type_, eq_slot, slots, cash, trade_block }
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

let cache : Map[Int, EquipData] = Map::new()

pub fn EquipData::get(id : Int) -> EquipData! {
  match cache.get(id) {
    Some(equip) => equip
    None => {
      let equip = EquipData::load!(id)
      cache.set(id, equip)
      equip
    }
  }
}

pub fn get_defstat(self : EquipData, stat : @stat.Id) -> Int {
  self.def_stats.get(stat).or(0)
}

pub fn get_eqslot(self : EquipData) -> @slot.Id {
  self.eq_slot
}

pub fn get_itemdata(self : EquipData) -> @item.ItemData {
  self.item_data
}
