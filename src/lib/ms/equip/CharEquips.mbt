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
  io_service : @io_task.IOService
  string_loader : @resource.SyncLoader
  clothes : Map[@slot.Id, (Int, @utils.Future[@clothing.Clothing?])]
  mut weapon_data_cache : @utils.Future[@weapon.WeaponData?]?
}

///|
pub fn CharEquips::new(
  io_service : @io_task.IOService,
  string_loader : @resource.SyncLoader
) -> CharEquips {
  { io_service, string_loader, clothes: Map::new(), weapon_data_cache: None }
}

///|
pub fn get_weapon(self : CharEquips) -> @weapon.WeaponData? {
  self.weapon_data_cache.map(fn(it) { it.poll() }).flatten().flatten()
}

///|
pub fn get_equip(self : CharEquips, slot : @slot.Id) -> Int {
  match self.clothes[slot] {
    Some((itemid, _)) => itemid
    None => 0
  }
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
  match self.clothes[slot] {
    Some((_, cloth)) =>
      match cloth.poll() {
        Some(Some(cloth)) => cloth.draw(stance, layer, frame, args)
        _ => ()
      }
    None => ()
  }
}

///| WARN: not accurate
pub fn getcaptype(self : CharEquips) -> CapType {
  match
    self.clothes[@slot.Id::HAT].map(fn(it) { it.1.poll() }).flatten().flatten() {
    Some(cap) =>
      match cap.get_vslot() {
        "CpH1H5" => CapType::HALF_COVER
        "CpH1H5AyAs" => CapType::FULL_COVER
        "CpH5" => CapType::HEADBAND
        _ => CapType::NONE
      }
    _ => CapType::NONE
  }
}

///|
pub fn has_overall(self : CharEquips) -> Bool {
  self.get_equip(@slot.Id::TOP) / 10000 == 105
}

///| WARN: not accurate
pub fn is_twohanded(self : CharEquips) -> Bool {
  match self.clothes[@slot.Id::WEAPON] {
    Some((_, weapon)) =>
      weapon.poll().flatten().map(fn(w) { w.is_twohanded() }).or(false)
    None => false
  }
}

///|
pub fn add_equip(
  self : CharEquips,
  item_id : Int,
  slot : @slot.Id,
  drawinfo : @types.BodyDrawInfo
) -> Unit {
  if item_id <= 0 {
    return
  }
  let mut cloth_res_ref : @clothing.Clothing?? = None
  self.clothes[slot] = (item_id, @utils.Future::new(fn() { cloth_res_ref }))
  let mut weapon_data_res_ref : @weapon.WeaponData?? = None
  self.weapon_data_cache = @utils.Future::new(fn() { weapon_data_res_ref })
    |> Some
  self.io_service.execute(
    fn() {
      let item_data = @item.ItemData::get_async(item_id, self.string_loader)
      let cloth = @clothing.Clothing::from_resource!(item_data, drawinfo)
      cloth_res_ref = Some(Some(cloth))
      if slot == @slot.Id::WEAPON {
        weapon_data_res_ref = Some(
          Some(@weapon.WeaponData::from_item_data!(item_data)),
        )
      }
    },
    on_error=fn(e) {
      @log.error(
        { "item_id": item_id, "err": Show::to_string(e) },
        "Failed to load clothing",
      )
      cloth_res_ref = Some(None)
      weapon_data_res_ref = Some(None)
    },
  )
}

///|
pub fn remove_equip(self : CharEquips, slot : @slot.Id) -> Unit {
  self.clothes.remove(slot)
  if slot == @slot.Id::WEAPON {
    self.weapon_data_cache = None
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
  guard self.clothes.get(@slot.Id::WEAPON) is Some((_, weapon)) else {
    return stance
  }
  guard weapon.poll().flatten() is Some(weapon) else { return stance }
  match stance {
    @types.StanceId::STAND1 | @types.StanceId::STAND2 => weapon.get_stand()
    @types.StanceId::WALK1 | @types.StanceId::WALK2 => weapon.get_walk()
    _ => stance
  }
}

///|
pub impl ToJson for CharEquips with to_json(self) -> Json {
  {
    "clothes": self.clothes.iter().map(fn(it) { (it.0, it.1.0) })
    |> Map::from_iter()
    |> ToJson::to_json(),
  }
}
