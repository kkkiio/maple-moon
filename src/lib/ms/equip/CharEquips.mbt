// Cap types (vslot)

///|
pub(all) enum CapType {
  NONE
  HEADBAND
  HAIRPIN
  HALF_COVER
  FULL_COVER
}

///|
/// A characters equipment (The visual part)
struct CharEquips {
  clothes : Map[@slot.Id, @clothing.Clothing]
  mut weapon_data : @weapon.WeaponData?
}

///|
pub fn CharEquips::new() -> CharEquips {
  { clothes: Map::new(), weapon_data: None }
}

///|
pub fn CharEquips::get_weapon(self : CharEquips) -> @weapon.WeaponData? {
  self.weapon_data
}

///|
pub fn CharEquips::get_equip(self : CharEquips, slot : @slot.Id) -> Int {
  self.clothes.get(slot).map(fn(it) { it.get_id() }).unwrap_or(0)
}

///|
pub fn CharEquips::get_clothing(
  self : CharEquips,
  slot : @slot.Id,
) -> @clothing.Clothing? {
  self.clothes.get(slot)
}

///|
/// WARN: not accurate
pub fn CharEquips::getcaptype(self : CharEquips) -> CapType {
  guard self.clothes.get(@slot.Id::HAT) is Some(cap) else {
    return CapType::NONE
  }
  match cap.get_vslot() {
    "CpH1H5" => CapType::HALF_COVER
    "CpH1H5AyAs" => CapType::FULL_COVER
    "CpH5" => CapType::HEADBAND
    _ => CapType::NONE
  }
}

///|
pub fn CharEquips::has_overall(self : CharEquips) -> Bool {
  self.get_equip(@slot.Id::TOP) / 10000 == 105
}

///|
pub fn CharEquips::is_two_handed(self : CharEquips) -> Bool {
  guard self.clothes.get(@slot.Id::WEAPON) is Some(weapon) else { return false }
  weapon.is_twohanded()
}

///|
pub fn CharEquips::add_equip(
  self : CharEquips,
  item_data : @item.ItemData,
  slot : @slot.Id,
  drawinfo : @types.BodyDrawInfo,
) -> Unit raise {
  let cloth = @clothing.Clothing::from_resource(item_data, drawinfo)
  self.clothes[slot] = cloth
  if slot == @slot.Id::WEAPON {
    self.weapon_data = Some(@weapon.WeaponData::from_item_data(item_data))
  }
}

///|
pub fn CharEquips::remove_equip(self : CharEquips, slot : @slot.Id) -> Unit {
  self.clothes.remove(slot)
  if slot == @slot.Id::WEAPON {
    self.weapon_data = None
  }
}

///|
pub fn CharEquips::has_weapon(self : CharEquips) -> Bool {
  self.clothes.get(@slot.Id::WEAPON) is Some(_)
}

///|
pub fn CharEquips::adjust_stance(
  self : CharEquips,
  stance : @types.StanceId,
) -> @types.StanceId {
  guard self.clothes.get(@slot.Id::WEAPON) is Some(weapon) else {
    return stance
  }
  match stance {
    @types.StanceId::STAND1 | @types.StanceId::STAND2 => weapon.get_stand()
    @types.StanceId::WALK1 | @types.StanceId::WALK2 => weapon.get_walk()
    _ => stance
  }
}

///|
pub fn CharEquips::iter(
  self : CharEquips,
) -> Iter[(@slot.Id, @clothing.Clothing)] {
  self.clothes.iter()
}
