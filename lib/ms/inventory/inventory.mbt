pub enum Movement {
  MOVE_NONE
  MOVE_INTERNAL
  MOVE_UNEQUIP
  MOVE_EQUIP
}

pub fn int_value(self : Movement) -> Int {
  match self {
    Movement::MOVE_NONE => -1
    Movement::MOVE_INTERNAL => 0
    Movement::MOVE_UNEQUIP => 1
    Movement::MOVE_EQUIP => 2
  }
}

pub enum Modification {
  ADD
  CHANGE_COUNT
  SWAP
  REMOVE
  ADD_COUNT
} derive(Eq, Hash)

pub fn int_value(self : Modification) -> Int {
  match self {
    Modification::ADD => 0
    Modification::CHANGE_COUNT => 1
    Modification::SWAP => 2
    Modification::REMOVE => 3
    Modification::ADD_COUNT => 4
  }
}

pub fn Modification::from_int(value : Int) -> Modification? {
  match value {
    0 => Modification::ADD |> Some
    1 => Modification::CHANGE_COUNT |> Some
    2 => Modification::SWAP |> Some
    3 => Modification::REMOVE |> Some
    4 => Modification::ADD_COUNT |> Some
    _ => None
  }
}

/// Return the move type by value
pub fn Movement::from_int(value : Int) -> Movement? {
  match value {
    -1 => Movement::MOVE_NONE |> Some
    0 => Movement::MOVE_INTERNAL |> Some
    1 => Movement::MOVE_UNEQUIP |> Some
    2 => Movement::MOVE_EQUIP |> Some
    _ => None
  }
}

// The player's inventory
struct Inventory {
  inventories : @utils.DefaultMap[TypeId, Map[Int, Slot]]
  items : Map[Int, Item]
  equips : Map[Int, @equip.Equip]
  pets : Map[Int, @pet.Pet]
  mut running_uid : Int
  total_stats : @utils.DefaultMap[@equip_stat.Id, Int]
  slot_maxima : Map[TypeId, Int]
  mut meso : Int
  mut bullet_slot : Int
}

struct Slot {
  unique_id : Int
  item_id : Int
  mut count : Int
  cash : Bool
}

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
    slot_maxima: Map::from_array([(TypeId::EQUIPPED, @slot.Id::length())]),
  }
}

/// Recalculate sums of equip stats
pub fn recalc_stats(self : Inventory, weapontype : @weapon.Type) -> Unit {
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

pub fn get_meso(self : Inventory) -> Int {
  self.meso
}

/// Set the meso amount.
pub fn set_meso(self : Inventory, meso : Int) -> Unit {
  self.meso = meso
}

pub fn set_slotmax(self : Inventory, type_id : TypeId, slotmax : Int) -> Unit {
  self.slot_maxima.set(type_id, slotmax)
}

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
  self.items.set(
    self.add_slot(invtype, slot, item_id, count, cash),
    { item_id, expiration, owner, flags },
  )
}

pub fn add_slot(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  count : Int,
  cash : Bool
) -> Int {
  self.running_uid += 1
  let unique_id = self.running_uid
  self.inventories[invtype][slot] = { unique_id, item_id, count, cash }
  unique_id
}

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

pub fn Inventory::add_equip(
  self : Inventory,
  invtype : TypeId,
  slot : Int,
  item_id : Int,
  cash : Bool,
  expiration : Int64,
  slots : Int,
  level : Int,
  stats : Map[@equip_stat.Id, Int],
  owner : String,
  flags : Int,
  item_level : Int,
  iexp : Int,
  vicious : Int
) -> Unit! {
  self.equips.set(
    self.add_slot(invtype, slot, item_id, 1, cash),
    {
      stats,
      item_id,
      expiration,
      owner,
      flags,
      slots,
      level,
      item_level,
      vicious,
      potential_rank: @equip.Potential::POT_NONE,
      quality: @equip.check_quality!(item_id, level > 0, stats),
    },
  )
}

pub fn get_stat(self : Inventory, stat : @equip_stat.Id) -> Int {
  self.total_stats[stat]
}

pub fn has_projectile(self : Inventory) -> Bool {
  self.bullet_slot > 0
}

pub fn get_bulletid(self : Inventory) -> Int {
  self.get_item_id(TypeId::USE, self.bullet_slot)
}

pub fn get_item_id(self : Inventory, t : TypeId, slot : Int) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.item_id }).or(0)
}

pub fn get_bulletcount(self : Inventory) -> Int {
  self.get_item_count(TypeId::USE, self.bullet_slot)
}

pub fn Inventory::get_item_count(
  self : Inventory,
  t : TypeId,
  slot : Int
) -> Int {
  self.inventories[t].get(slot).map(fn(it) { it.count }).or(0)
}

pub fn modify(
  self : Inventory,
  t : TypeId,
  slot : Int,
  mode : Modification,
  arg : Int,
  move : Movement
) -> Unit {
  let (slot, t) = if slot < 0 { (-slot, TypeId::EQUIPPED) } else { (slot, t) }
  let arg = arg.abs()
  match mode {
    Modification::CHANGE_COUNT => self.change_count(t, slot, arg)
    Modification::SWAP =>
      match move {
        Movement::MOVE_INTERNAL => self.swap(t, slot, t, arg)
        Movement::MOVE_UNEQUIP =>
          self.swap(TypeId::EQUIPPED, slot, TypeId::EQUIP, arg)
        Movement::MOVE_EQUIP =>
          self.swap(TypeId::EQUIP, slot, TypeId::EQUIPPED, arg)
        _ => ()
      }
    Modification::REMOVE => self.remove(t, slot)
    _ => panic()
  }
}

pub fn swap(
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

pub fn remove(self : Inventory, t : TypeId, slot_id : Int) -> Unit {
  guard let Some(slot) = self.inventories[t].get(slot_id) else {
    None => return
  }
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

pub fn change_count(
  self : Inventory,
  t : TypeId,
  slot : Int,
  count : Int
) -> Unit {
  match self.inventories[t].get(slot) {
    Some(slot) => slot.count = count
    None => ()
  }
}

pub fn get_bulletslot(self : Inventory) -> Int {
  self.bullet_slot
}

pub fn get_slotmax(self : Inventory, t : TypeId) -> Int {
  self.slot_maxima.get(t).or(0)
}
