// Cap types (vslot)
pub enum CapType {
  NONE
  HEADBAND
  HAIRPIN
  HALF_COVER
  FULL_COVER
}

/// A characters equipment (The visual part)
struct CharEquips {
  clothes : Map[@slot.Id, @clothing.Clothing]
}

pub fn CharEquips::new() -> CharEquips {
  { clothes: Map::new() }
}

pub fn CharEquips::get_weapon(self : CharEquips) -> Int {
  self.get_equip(@slot.Id::WEAPON)
}

pub fn CharEquips::get_equip(self : CharEquips, slot : @slot.Id) -> Int {
  match self.clothes[slot] {
    Some(cloth) => cloth.get_id()
    None => 0
  }
}

pub fn CharEquips::draw(
  self : CharEquips,
  slot : @slot.Id,
  stance : @char_look.StanceId,
  layer : @clothing.Layer,
  frame : Int,
  args : @graphics.DrawArgument
) -> Unit {
  match self.clothes[slot] {
    Some(cloth) => cloth.draw(stance, layer, frame, args)
    None => ()
  }
}

pub fn CharEquips::getcaptype(self : CharEquips) -> CapType {
  match self.clothes[@slot.Id::HAT] {
    Some(cap) =>
      match cap.get_vslot() {
        "CpH1H5" => CapType::HALF_COVER
        "CpH1H5AyAs" => CapType::FULL_COVER
        "CpH5" => CapType::HEADBAND
        _ => CapType::NONE
      }
    None => CapType::NONE
  }
}

pub fn CharEquips::has_overall(self : CharEquips) -> Bool {
  self.get_equip(@slot.Id::TOP) / 10000 == 105
}

pub fn CharEquips::is_twohanded(self : CharEquips) -> Bool {
  match self.clothes[@slot.Id::WEAPON] {
    Some(weapon) => weapon.is_twohanded()
    None => false
  }
}

pub fn add_equip(
  self : CharEquips,
  itemid : Int,
  drawinfo : @char_look.BodyDrawInfo
) -> Unit! {
  if itemid <= 0 {
    return
  }
  let cloth = match cloth_cache.get(itemid) {
    Some(cloth) => cloth
    None => {
      let cloth = @clothing.Clothing::new!(itemid, drawinfo)
      cloth_cache.set(itemid, cloth)
      cloth
    }
  }
  let slot = cloth.get_eqslot()
  self.clothes[slot] = cloth
}

let cloth_cache : Map[Int, @clothing.Clothing] = Map::new()
