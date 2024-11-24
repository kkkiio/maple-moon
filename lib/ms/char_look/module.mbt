struct Module {
  draw_info : BodyDrawInfo
  hair_cache : Map[Int, @utils.Future[Hair]]
  face_types : Map[Int, @utils.Future[Face]]
  body_cache : Map[Int, @utils.Future[Body]]
}

pub fn Module::load() -> @utils.Future[Module] {
  let bodynode = body_loader.load_res(["00002000.img"])
  let headnode = body_loader.load_res(["00012000.img"])
  bodynode
  .combine(headnode)
  .map(
    fn(it) {
      let (bodynode, headnode) = it
      Module::new(bodynode, headnode)
    },
  )
}

pub fn Module::new(
  bodynode : @resource.NxNode,
  headnode : @resource.NxNode
) -> Module {
  {
    hair_cache: Map::new(),
    draw_info: BodyDrawInfo::new(bodynode, headnode),
    face_types: Map::new(),
    body_cache: Map::new(),
  }
}

pub fn get_body_draw_info(self : Module) -> BodyDrawInfo {
  self.draw_info
}

pub fn load_body_by_skin_id(
  self : Module,
  skin_id : Int
) -> @utils.Future[Body] {
  self.body_cache.get_or_init(
    skin_id,
    fn() { Body::load(skin_id, self.draw_info) },
  )
}

pub fn load_hair_by_id(self : Module, hair_id : Int) -> @utils.Future[Hair] {
  self.hair_cache.get_or_init(
    hair_id,
    fn() { Hair::load(hair_id, self.draw_info) },
  )
}

pub fn load_face_by_id(self : Module, face_id : Int) -> @utils.Future[Face] {
  self.face_types.get_or_init(face_id, fn() { Face::load(face_id) })
}
