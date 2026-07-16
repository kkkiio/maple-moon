///|
pub struct MapPortals {
  map_portals_animations : MapPortalAnimations
  id_portal_map : Map[Int, Portal]
  name_portal_id_map : Map[String, Int]
  mut manual_cooldown : Int
  mut auto_cooldown : Int
}

///|
let warpcd : Int = 48

///|
struct MapPortalAnimations {
  animations : Map[PortalType, @ms_animation.Animation]
}

///|
pub fn MapPortals::MapPortals(
  src : Array[NxPortal],
  mapid : Int,
  map_portals_animations : MapPortalAnimations,
) -> MapPortals {
  let portals_by_id = Map([])
  let name_portal_id_map = Map([])
  for portal_id, res in src {
    let portal_type = res.pt
    let name = res.pn
    let target_name = res.tn
    let target_id = res.tm
    let position = Point(res.x, res.y)
    let animation = map_portals_animations.animations.get(portal_type)
    let intramap = target_id == mapid
    portals_by_id.set(
      portal_id,
      Portal(
        animation, portal_type, name, intramap, position, target_id, target_name,
      ),
    )
    name_portal_id_map.set(name, portal_id)
  }
  {
    id_portal_map: portals_by_id,
    name_portal_id_map,
    manual_cooldown: 0,
    auto_cooldown: 0,
    map_portals_animations,
  }
}

///|
pub fn MapPortals::from_tiled_map(
  map : @tiled.TiledMap,
  mapid : Int,
  map_portals_animations : MapPortalAnimations,
) -> MapPortals raise {
  guard map.object_layer("portal") is Some(portal_layer) else {
    fail("missing `portal` layer in map.tmj")
  }
  let src = []
  for obj in portal_layer.objects {
    src.push(nx_portal_from_tiled_object(obj))
  }
  MapPortals(src, mapid, map_portals_animations)
}

///|
fn nx_portal_from_tiled_object(obj : @tiled.TiledObject) -> NxPortal raise {
  let pn = tiled_object_string_required(obj, "pn")
  let tm = tiled_object_int_required(obj, "tm")
  let tn = tiled_object_string_required(obj, "tn")
  let x = tiled_object_int_required(obj, "x")
  let y = tiled_object_int_required(obj, "y")
  let pt_id = tiled_object_int_required(obj, "pt")
  let pt = match PortalType::typebyid(pt_id) {
    Some(pt) => pt
    None => fail("invalid portal type `pt=\{pt_id}`, object_id=\{obj.id}")
  }
  { pn, tm, tn, x, y, pt }
}

///|
fn tiled_object_string_required(
  obj : @tiled.TiledObject,
  name : String,
) -> String raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(_) =>
      fail("object property '\{name}' must be string, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn tiled_object_int_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Int raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => value
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int()
    Some(_) =>
      fail("object property '\{name}' must be int, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
pub fn MapPortals::get_portal_pos_by_id(
  self : MapPortals,
  portal_id : Int,
) -> Point[Int]? {
  self.id_portal_map
  .get(portal_id)
  .map(fn(portal) { portal.get_position() - Point(0, 30) })
}

///|
pub fn MapPortals::get_portal_by_name(
  self : MapPortals,
  portal_name : String,
) -> Point[Int]? {
  self.name_portal_id_map
  .get(portal_name)
  .bind(fn(portal_id) { self.get_portal_pos_by_id(portal_id) })
}

///|
fn MapPortals::find_warp_at_by_mode(
  self : MapPortals,
  playerpos : Point[Int],
  auto_trigger : Bool,
) -> PortalWarpInfo? {
  let cooldown = if auto_trigger {
    self.auto_cooldown
  } else {
    self.manual_cooldown
  }
  guard cooldown == 0 else { return None }
  let matched = self.id_portal_map
    .iter()
    .map(fn(it) { it.1 })
    .find_first(fn(portal) {
      let portal_type = portal.get_type()
      let matches_trigger_mode = if auto_trigger {
        portal_type.is_auto_trigger()
      } else {
        portal_type.is_manual_trigger()
      }
      portal.warp_info.map_id < 999999999 &&
      portal.bounds().contains(playerpos) &&
      matches_trigger_mode
    })
  guard matched is Some(portal) else { return None }
  if auto_trigger {
    self.auto_cooldown = warpcd
  } else {
    self.manual_cooldown = warpcd
  }
  Some(portal.warp_info)
}

///|
/// Find a manually triggered warp portal at `playerpos`.
pub fn MapPortals::find_manual_warp_at(
  self : MapPortals,
  playerpos : Point[Int],
) -> PortalWarpInfo? {
  self.find_warp_at_by_mode(playerpos, false)
}

///|
/// Find an auto-triggered warp portal at `playerpos`.
pub fn MapPortals::find_auto_warp_at(
  self : MapPortals,
  playerpos : Point[Int],
) -> PortalWarpInfo? {
  self.find_warp_at_by_mode(playerpos, true)
}

///|
/// Find a manually triggered warp portal at `playerpos`.
pub fn MapPortals::find_warp_at(
  self : MapPortals,
  playerpos : Point[Int],
) -> PortalWarpInfo? {
  self.find_manual_warp_at(playerpos)
}

///|
pub fn MapPortalAnimations::load() -> MapPortalAnimations {
  { animations: Map([]) }
}

///|
priv struct PortalsContext {
  portals : MapPortals
  portal_entities : Map[Int, @entity.Entity]
  get_touch_pos : () -> Point[Int]?
  mut dirty : Bool
}

///|
let portals_context : Ref[PortalsContext?] = Ref(None)

///|
pub fn set_portals(
  portals : MapPortals,
  get_touch_pos? : () -> Point[Int]? = fn() { None },
) -> Unit {
  if portals_context.val is Some(ctx) {
    destroy_entities_iter(ctx.portal_entities.values())
  }
  portals_context.val = Some({
    portals,
    portal_entities: Map([]),
    get_touch_pos,
    dirty: true,
  })
}

///|
/// Find a manually triggered warp portal at `playerpos` from current portals context.
pub fn find_manual_warp_at_current(playerpos : Point[Int]) -> PortalWarpInfo? {
  portals_context.val.bind(fn(ctx) {
    ctx.portals.find_manual_warp_at(playerpos)
  })
}

///|
/// Find an auto-triggered warp portal at `playerpos` from current portals context.
pub fn find_auto_warp_at_current(playerpos : Point[Int]) -> PortalWarpInfo? {
  portals_context.val.bind(fn(ctx) { ctx.portals.find_auto_warp_at(playerpos) })
}

///|
/// Find a manually triggered warp portal at `playerpos` from current portals context.
pub fn find_warp_at_current(playerpos : Point[Int]) -> PortalWarpInfo? {
  find_manual_warp_at_current(playerpos)
}

///|
/// Resolve portal spawn point by portal name from current portals context.
pub fn get_portal_by_name_current(portal_name : String) -> Point[Int]? {
  portals_context.val.bind(fn(ctx) {
    ctx.portals.get_portal_by_name(portal_name)
  })
}

///|
/// Resolve portal spawn point by portal id from current portals context.
pub fn get_portal_pos_by_id_current(portal_id : Int) -> Point[Int]? {
  portals_context.val.bind(fn(ctx) {
    ctx.portals.get_portal_pos_by_id(portal_id)
  })
}

///|
/// Return a JSON snapshot of the portals loaded for the current map.
///
/// The snapshot is empty when no map has installed a portals context yet. The
/// fields are intended for debug tooling and playtest scripts, so callers
/// should treat the result as read-only observation data.
///
/// # Example
/// ```moonbit nocheck
/// let portals = @map.current_portals_json()
/// inspect(portals.stringify())
/// ```
pub fn current_portals_json() -> Json {
  let entries : Array[Json] = []
  match portals_context.val {
    Some(ctx) =>
      for id, portal in ctx.portals.id_portal_map {
        let position = portal.get_position()
        let bounds = portal.bounds()
        let warp = portal.getwarpinfo()
        let portal_type = portal.get_type()
        let entry : Json = {
          "id": id,
          "name": portal.get_name(),
          "type": ToJson::to_json(portal_type),
          "x": position.x,
          "y": position.y,
          "targetMapId": warp.map_id,
          "targetPortalName": warp.toname,
          "intraMap": warp.intra_map,
          "manualTrigger": portal_type.is_manual_trigger(),
          "autoTrigger": portal_type.is_auto_trigger(),
          "bounds": {
            "left": bounds.left(),
            "top": bounds.top(),
            "right": bounds.right(),
            "bottom": bounds.bottom(),
          },
        }
        entries.push(entry)
      }
    None => ()
  }
  entries.to_json()
}

///|
pub fn portal_system(_world : @ecs.World) -> Unit {
  guard portals_context.val is Some(ctx) else { return }
  if ctx.dirty {
    ensure_portal_entities(ctx)
    ctx.dirty = false
  }
  let touch_pos = (ctx.get_touch_pos)()
  for id, portal in ctx.portals.id_portal_map {
    match portal.get_type() {
      PortalType::HIDDEN | PortalType::COLLISION => {
        let entity = ctx.portal_entities.get(id)
        guard entity is Some(entity) else { abort("portal entity not found") }
        portal.update_touched(entity, touch_pos)
      }
      _ => ()
    }
  }
  if ctx.portals.manual_cooldown > 0 {
    ctx.portals.manual_cooldown -= 1
  }
  if ctx.portals.auto_cooldown > 0 {
    ctx.portals.auto_cooldown -= 1
  }
}

///|
fn ensure_portal_entities(ctx : PortalsContext) -> Unit {
  for id, portal in ctx.portals.id_portal_map {
    if ctx.portal_entities.contains(id) {
      continue
    }
    let entity = @entity.Entity()
    let position = portal.get_position()
    @transform2d.set_xy(
      entity,
      @selene_math.Vec2(position.x.to_double(), position.y.to_double()),
    )
    if portal.animation is Some(animation) {
      let sprite = @ms_animation.sprite_from_animation(
        animation,
        @graphics.PORTAL_ZINDEX,
      )
      @sprite.sprites().set(entity, sprite)
    }
    ctx.portal_entities.set(id, entity)
  }
}

///|
fn destroy_entities_iter(entities : Iter[@entity.Entity]) -> Unit {
  entities.each(fn(e) { e.destroy() })
}

///|
test "parse portals" {
  let json : Json = {
    "0": { "pn": "sp", "pt": 0, "tm": 999999999, "tn": "", "x": -258, "y": 138 },
    "1": { "pn": "sp", "pt": 0, "tm": 999999999, "tn": "", "x": 1115, "y": 66 },
    "2": {
      "pn": "in00",
      "pt": 1,
      "script": "",
      "tm": 103000102,
      "tn": "out00",
      "x": 3120,
      "y": 155,
    },
    "3": {
      "pn": "out00",
      "pt": 2,
      "script": "",
      "tm": 103000100,
      "tn": "in00",
      "x": -230,
      "y": 194,
    },
  }
  let res : @res.MapBasedArray[NxPortal] = @json.from_json(json)
  json_inspect(res.0, content=[
    {
      "pn": "sp",
      "tm": 999999999,
      "tn": "",
      "x": -258,
      "y": 138,
      "pt": "SPAWN",
    },
    { "pn": "sp", "tm": 999999999, "tn": "", "x": 1115, "y": 66, "pt": "SPAWN" },
    {
      "pn": "in00",
      "tm": 103000102,
      "tn": "out00",
      "x": 3120,
      "y": 155,
      "pt": "INVISIBLE",
    },
    {
      "pn": "out00",
      "tm": 103000100,
      "tn": "in00",
      "x": -230,
      "y": 194,
      "pt": "REGULAR",
    },
  ])
}

///|
fn make_test_portals(src : Array[NxPortal]) -> MapPortals {
  MapPortals(src, 101010103, { animations: Map([]) })
}

///|
test "manual and auto portal queries are split by portal type" {
  let portals = make_test_portals([
    {
      pn: "goSleepy0",
      tm: 105040300,
      tn: "jumpSP",
      x: 100,
      y: 2058,
      pt: PortalType::COLLISION,
    },
    {
      pn: "under00",
      tm: 101010102,
      tn: "top00",
      x: 200,
      y: 100,
      pt: PortalType::REGULAR,
    },
  ])
  let invisible_portals = make_test_portals([
    {
      pn: "in00",
      tm: 101000000,
      tn: "out00",
      x: 300,
      y: 100,
      pt: PortalType::INVISIBLE,
    },
  ])
  debug_inspect(
    portals.find_auto_warp_at(Point(100, 2058)).map(fn(warp) { warp.name }),
    content="Some(\"goSleepy0\")",
  )
  debug_inspect(
    portals.find_manual_warp_at(Point(100, 2058)) is None,
    content="true",
  )
  debug_inspect(
    portals.find_manual_warp_at(Point(200, 100)).map(fn(warp) { warp.name }),
    content="Some(\"under00\")",
  )
  debug_inspect(
    portals.find_auto_warp_at(Point(200, 100)) is None,
    content="true",
  )
  debug_inspect(
    invisible_portals
    .find_manual_warp_at(Point(300, 100))
    .map(fn(warp) { warp.name }),
    content="Some(\"in00\")",
  )
}

///|
test "manual and auto portal cooldowns are independent" {
  let portals = make_test_portals([
    {
      pn: "goSleepy0",
      tm: 105040300,
      tn: "jumpSP",
      x: 100,
      y: 2058,
      pt: PortalType::COLLISION,
    },
    {
      pn: "under00",
      tm: 101010102,
      tn: "top00",
      x: 100,
      y: 2058,
      pt: PortalType::REGULAR,
    },
  ])
  debug_inspect(
    portals.find_manual_warp_at(Point(100, 2058)).map(fn(warp) { warp.name }),
    content="Some(\"under00\")",
  )
  debug_inspect(
    portals.find_auto_warp_at(Point(100, 2058)).map(fn(warp) { warp.name }),
    content="Some(\"goSleepy0\")",
  )
  debug_inspect(
    portals.find_manual_warp_at(Point(100, 2058)) is None,
    content="true",
  )
  debug_inspect(
    portals.find_auto_warp_at(Point(100, 2058)) is None,
    content="true",
  )
}
