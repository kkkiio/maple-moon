///|
struct MapPortals {
  map_portals_animations : MapPortalAnimations
  portals_by_id : @immut/sorted_map.T[Int, Portal]
  portal_ids_by_name : @immut/sorted_map.T[String, Int]
  mut cooldown : Int
}

///|
let warpcd : Int = 48

///|
struct MapPortalAnimations {
  animations : @immut/sorted_map.T[PortalType, @graphics.Animation]
}

///|
pub fn MapPortals::new(
  src : Array[PortalMarker],
  mapid : Int,
  map_portals_animations : MapPortalAnimations
) -> MapPortals {
  let mut portals_by_id = @immut/sorted_map.new()
  let mut portal_ids_by_name = @immut/sorted_map.new()
  for portal_id, res in src {
    let portal_type = res.pt
    let name = res.pn
    let target_name = res.tn
    let target_id = res.tm
    let position = Point::new(res.x, res.y)
    let animation = map_portals_animations.animations[portal_type]
    let intramap = target_id == mapid
    portals_by_id = portals_by_id.add(
      portal_id,
      Portal::new(
        animation, portal_type, name, intramap, position, target_id, target_name,
      ),
    )
    portal_ids_by_name = portal_ids_by_name.add(name, portal_id)
  }
  {
    portals_by_id,
    portal_ids_by_name,
    cooldown: warpcd,
    map_portals_animations,
  }
}

///|
pub fn MapPortals::update(self : MapPortals, playerpos : Point[Int]) -> Unit {
  self.map_portals_animations.animations[PortalType::REGULAR]
  .unwrap()
  .update(timestep=@config.step_time_ms)
  |> ignore
  self.map_portals_animations.animations[PortalType::HIDDEN]
  .unwrap()
  .update(timestep=@config.step_time_ms)
  |> ignore
  for _, portal in self.portals_by_id {
    match portal.get_type() {
      PortalType::HIDDEN | PortalType::TOUCH => portal.update(playerpos)
      _ => ()
    }
  }
  if self.cooldown > 0 {
    self.cooldown -= 1
  }
}

///|
pub fn MapPortals::draw(
  self : MapPortals,
  viewpos : Point[Int],
  inter : Double
) -> Unit {
  self.portals_by_id.each(fn(_k, portal) { portal.draw(viewpos, inter) })
}

///|
pub fn get_portal_by_id(self : MapPortals, portal_id : Int) -> Point[Int] {
  match self.portals_by_id[portal_id] {
    Some(portal) => portal.get_position() - @struct.Point::new(0, 30)
    None => @struct.Point::default()
  }
}

///|
pub fn get_portal_by_name(
  self : MapPortals,
  portal_name : String
) -> Point[Int] {
  match self.portal_ids_by_name[portal_name] {
    Some(portal_id) => self.get_portal_by_id(portal_id)
    None => @struct.Point::default()
  }
}

///|
pub fn find_warp_at(
  self : MapPortals,
  playerpos : Point[Int]
) -> PortalWarpInfo {
  if self.cooldown == 0 {
    self.cooldown = warpcd
    match
      self.portals_by_id
      .iter()
      .map(fn(it) { it.1 })
      .find_first(fn(portal) { portal.bounds().contains(playerpos) }) {
      Some(portal) => return portal.getwarpinfo()
      None => ()
    }
  }
  PortalWarpInfo::default()
}

///|
pub fn MapPortalAnimations::load() -> @utils.Future[MapPortalAnimations] {
  map_helper_loader
  .load_res(["portal", "game", "ph", "default", "portalContinue"])
  .combine(map_helper_loader.load_res(["portal", "game", "pv"]))
  .map(fn(it) {
    let (src1, src2) = it
    {
      animations: @immut/sorted_map.from_array([
        (PortalType::HIDDEN, @graphics.Animation::from_resource(src1)),
        (PortalType::REGULAR, @graphics.Animation::from_resource(src2)),
      ]),
    }
  })
}

///|
let map_helper_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "maphelper",
)
