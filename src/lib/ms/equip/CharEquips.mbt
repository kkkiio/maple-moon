// Cap types (vslot)
///|
pub(all) enum CapType {
  NONE
  HEADBAND
  HAIRPIN
  HALF_COVER
  FULL_COVER
}

///| A characters equipment (The visual part)
struct CharEquips {
  clothes : Map[@slot.Id, @clothing.Clothing]
  mut weapon_data : @weapon.WeaponData?
}

///|
pub fn CharEquips::new() -> CharEquips {
  { clothes: Map::new(), weapon_data: None }
}

///|
pub fn get_weapon(self : CharEquips) -> @weapon.WeaponData? {
  self.weapon_data
}

///|
pub fn get_equip(self : CharEquips, slot : @slot.Id) -> Int {
  self.clothes.get(slot).map(fn(it) { it.get_id() }).or(0)
}

///|
pub fn CharEquips::draw(
  self : CharEquips,
  slot : @slot.Id,
  stance : @types.StanceId,
  layer : @clothing.Layer,
  frame : Int,
  args : @graphics.DrawArgument
) -> Unit {
  guard self.clothes.get(slot) is Some(cloth) else { return }
  cloth.draw(stance, layer, frame, args)
}

///| WARN: not accurate
pub fn getcaptype(self : CharEquips) -> CapType {
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
pub fn has_overall(self : CharEquips) -> Bool {
  self.get_equip(@slot.Id::TOP) / 10000 == 105
}

///|
pub fn is_twohanded(self : CharEquips) -> Bool {
  guard self.clothes.get(@slot.Id::WEAPON) is Some(weapon) else { return false }
  weapon.is_twohanded()
}

///|
pub fn add_equip(
  self : CharEquips,
  item_data : @item.ItemData,
  slot : @slot.Id,
  drawinfo : @types.BodyDrawInfo
) -> Unit raise {
  let cloth = @clothing.Clothing::from_resource(item_data, drawinfo)
  self.clothes[slot] = cloth
  if slot == @slot.Id::WEAPON {
    self.weapon_data = Some(@weapon.WeaponData::from_item_data(item_data))
  }
}

///|
pub fn remove_equip(self : CharEquips, slot : @slot.Id) -> Unit {
  self.clothes.remove(slot)
  if slot == @slot.Id::WEAPON {
    self.weapon_data = None
  }
}

///|
pub fn has_weapon(self : CharEquips) -> Bool {
  self.clothes.get(@slot.Id::WEAPON) is Some(_)
}

///|
pub fn adjust_stance(
  self : CharEquips,
  stance : @types.StanceId
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
pub impl ToJson for CharEquips with to_json(self) -> Json {
  { "clothes": self.clothes }
}
