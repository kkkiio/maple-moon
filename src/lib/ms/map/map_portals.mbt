///|
pub struct MapPortals {
  map_portals_animations : MapPortalAnimations
  id_portal_map : Map[Int, Portal]
  name_portal_id_map : Map[String, Int]
  mut cooldown : Int
}

///|
let warpcd : Int = 48

///|
struct MapPortalAnimations {
  animations : Map[PortalType, @sprite.Animation]
}

///|
pub fn MapPortals::new(
  src : Array[NxPortal],
  mapid : Int,
  map_portals_animations : MapPortalAnimations,
) -> MapPortals {
  let portals_by_id = Map::new()
  let name_portal_id_map = Map::new()
  for portal_id, res in src {
    let portal_type = res.pt
    let name = res.pn
    let target_name = res.tn
    let target_id = res.tm
    let position = Point::new(res.x, res.y)
    let animation = map_portals_animations.animations.get(portal_type)
    let intramap = target_id == mapid
    portals_by_id.set(
      portal_id,
      Portal::new(
        animation, portal_type, name, intramap, position, target_id, target_name,
      ),
    )
    name_portal_id_map.set(name, portal_id)
  }
  {
    id_portal_map: portals_by_id,
    name_portal_id_map,
    cooldown: warpcd,
    map_portals_animations,
  }
}

///|
pub fn MapPortals::get_portal_pos_by_id(
  self : MapPortals,
  portal_id : Int,
) -> Point[Int] {
  match self.id_portal_map.get(portal_id) {
    Some(portal) => portal.get_position() - @struct.Point::new(0, 30)
    None => @struct.Point::default()
  }
}

///|
pub fn MapPortals::get_portal_by_name(
  self : MapPortals,
  portal_name : String,
) -> Point[Int] {
  self.name_portal_id_map
  .get(portal_name)
  .map(self.get_portal_pos_by_id(_))
  .unwrap_or_default()
}

///|
pub fn MapPortals::find_warp_at(
  self : MapPortals,
  playerpos : Point[Int],
) -> PortalWarpInfo? {
  guard self.cooldown == 0 else { return None }
  self.cooldown = warpcd
  if self.id_portal_map
    .iter()
    .map(fn(it) { it.1 })
    .find_first(fn(portal) {
      portal.warp_info.map_id < 999999999 && portal.bounds().contains(playerpos)
    })
    is Some(portal) {
    return Some(portal.warp_info)
  }
  None
}

///|
pub fn MapPortalAnimations::load() -> MapPortalAnimations {
  let ani1 = @sprite.Animation::new(
    @sprite.frames_from_atlas(
      "/assets/portal/continue.png",
      7,
      width=128,
      height=122,
    ),
    transform=@selene_math.Transform::from_translation(-62.0, -199.0),
    // offset=-@selene_math.Vec2D(62, 199),
  )
  let ani2 = @sprite.Animation::new(
    @sprite.frames_from_atlas(
      "/assets/portal/regular.png",
      8,
      width=89,
      height=257,
    ),
    transform=@selene_math.Transform::from_translation(-44.0, -248.0),
    // offset=-@selene_math.Vec2D(44, 248),
  )
  {
    animations: Map::from_array([
      (PortalType::HIDDEN, ani1),
      (PortalType::REGULAR, ani2),
      (PortalType::SCRIPTED, ani2),
    ]),
  }
}

///|
priv struct PortalsContext {
  portals : MapPortals
  portal_entities : Map[Int, @entity.Entity]
  get_touch_pos : () -> Point[Int]?
  mut dirty : Bool
}

///|
let portals_context : Ref[PortalsContext?] = Ref::new(None)

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
    portal_entities: Map::new(),
    get_touch_pos,
    dirty: true,
  })
}

///|
pub fn portal_system(_delta : Double) -> Unit {
  guard portals_context.val is Some(ctx) else { return }
  if ctx.dirty {
    ensure_portal_entities(ctx)
    ctx.dirty = false
  }
  let touch_pos = (ctx.get_touch_pos)()
  for id, portal in ctx.portals.id_portal_map {
    match portal.get_type() {
      PortalType::HIDDEN | PortalType::TOUCH => {
        let entity = ctx.portal_entities.get(id)
        guard entity is Some(entity) else { abort("portal entity not found") }
        portal.update_touched(entity, touch_pos)
      }
      _ => ()
    }
  }
  if ctx.portals.cooldown > 0 {
    ctx.portals.cooldown -= 1
  }
}

///|
fn ensure_portal_entities(ctx : PortalsContext) -> Unit {
  for id, portal in ctx.portals.id_portal_map {
    if ctx.portal_entities.contains(id) {
      continue
    }
    let entity = @entity.Entity::new()
    let position = portal.get_position()
    @position.positions.set(
      entity,
      @position.Position(
        @selene_math.Vec2D(position.x.to_double(), position.y.to_double()),
      ),
    )
    if portal.animation is Some(animation) {
      let sprite = @sprite.Sprite::from_animation(
        animation,
        @graphics.PORTAL_ZINDEX,
      )
      @sprite.sprites.set(entity, sprite)
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
  let res : @resource.MapBasedArray[NxPortal] = @json.from_json(json)
  @json.inspect(res.0, content=[
    {
      "pn": "sp",
      "tn": "",
      "x": -258,
      "y": 138,
      "tm": 999999999,
      "pt": "SPAWN",
    },
    { "pn": "sp", "tn": "", "x": 1115, "y": 66, "tm": 999999999, "pt": "SPAWN" },
    {
      "pn": "in00",
      "tn": "out00",
      "x": 3120,
      "y": 155,
      "tm": 103000102,
      "pt": "INVISIBLE",
    },
    {
      "pn": "out00",
      "tn": "in00",
      "x": -230,
      "y": 194,
      "tm": 103000100,
      "pt": "REGULAR",
    },
  ])
}
