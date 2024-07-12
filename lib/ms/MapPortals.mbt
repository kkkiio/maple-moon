struct MapPortals {
  mut portals_by_id : @immut/sorted_map.Map[Int, Portal]
  mut portal_ids_by_name : @immut/sorted_map.Map[String, Int]
  mut cooldown : Int
}

let warpcd : Int = 48

struct MapPortalAnimations {
  mut animations : @immut/sorted_map.Map[PortalType, Animation]
}

let map_portals_animations : MapPortalAnimations = {
  animations: @immut/sorted_map.empty(),
}

pub fn MapPortals::from_resource(src : NxNode, mapid : Int) -> MapPortals {
  let mut portals_by_id = @immut/sorted_map.empty()
  let mut portal_ids_by_name = @immut/sorted_map.empty()
  src.each(
    fn(sub) {
      let portal_id = @strconv.parse_int(sub.name)!!.or(-1)
      if portal_id >= 0 {
        let portal_type = PortalType::typebyid(sub["pt"].get_int().unwrap())
        let name = sub["pn"].get_string()
        let target_name = sub["tn"].get_string()
        let target_id = sub["tm"].get_int().unwrap()
        let position = Point::new(
          sub["x"].get_int().unwrap(),
          sub["y"].get_int().unwrap(),
        )
        let animation = map_portals_animations.animations[portal_type]
        let intramap = target_id == mapid
        portals_by_id = portals_by_id.insert(
          portal_id,
          Portal::new(
            animation, portal_type, name, intramap, position, target_id, target_name,
          ),
        )
        portal_ids_by_name = portal_ids_by_name.insert(name, portal_id)
      }
    },
  )
  { portals_by_id, portal_ids_by_name, cooldown: warpcd }
}

pub fn MapPortals::default() -> MapPortals {
  {
    portals_by_id: @immut/sorted_map.empty(),
    portal_ids_by_name: @immut/sorted_map.empty(),
    cooldown: warpcd,
  }
}

pub fn update(self : MapPortals, playerpos : Point[Int]) -> Unit {
  map_portals_animations.animations[PortalType::REGULAR].unwrap().update(
    timestep=@Constants.timestep,
  )
  |> ignore
  map_portals_animations.animations[PortalType::HIDDEN].unwrap().update(
    timestep=@Constants.timestep,
  )
  |> ignore
  self.portals_by_id.each(
    fn(_k, portal) {
      match portal.get_type() {
        PortalType::HIDDEN | PortalType::TOUCH => portal.update(playerpos)
        _ => ()
      }
    },
  )
  if self.cooldown > 0 {
    self.cooldown -= 1
  }
}

pub fn draw(self : MapPortals, viewpos : Point[Int], inter : Double) -> Unit {
  self.portals_by_id.each(fn(_k, portal) { portal.draw(viewpos, inter) })
}

pub fn get_portal_by_id(self : MapPortals, portal_id : Int) -> Point[Int] {
  match self.portals_by_id[portal_id] {
    Some(portal) => portal.get_position() - Point::new(0, 30)
    None => Point::default()
  }
}

pub fn get_portal_by_name(
  self : MapPortals,
  portal_name : String
) -> Point[Int] {
  match self.portal_ids_by_name[portal_name] {
    Some(portal_id) => self.get_portal_by_id(portal_id)
    None => Point::default()
  }
}

pub fn find_warp_at(
  self : MapPortals,
  playerpos : Point[Int]
) -> PortalWarpInfo {
  if self.cooldown == 0 {
    self.cooldown = warpcd
    match
      self.portals_by_id.iter().map(fn(it) { it.1 }).find_first(
        fn(portal) { portal.bounds().contains(playerpos) },
      ) {
      Some(portal) => return portal.getwarpinfo()
      None => ()
    }
  }
  PortalWarpInfo::default()
}

pub fn MapPortalAnimations::load(self : MapPortalAnimations) -> Unit {
  let loader = map_loader()
  let src1 = loader.load_res(
    ["MapHelper.img", "portal", "game", "ph", "default", "portalContinue"],
  )
  let src2 = loader.load_res(["MapHelper.img", "portal", "game", "pv"])
  self.animations = @immut/sorted_map.from_array(
    [
      (PortalType::HIDDEN, Animation::from_resource(src1)),
      (PortalType::REGULAR, Animation::from_resource(src2)),
    ],
  )
}
