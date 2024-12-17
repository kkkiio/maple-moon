///|
struct Module {
  draw_info : @types.BodyDrawInfo
  hair_cache : Map[Int, @utils.Future[Hair]]
  face_types : Map[Int, @utils.Future[Face]]
  body_cache : Map[Int, @utils.Future[Body]]
  mut char_look : CharLook?
}

///|
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

///|
pub fn Module::new(
  bodynode : @resource.NxNode,
  headnode : @resource.NxNode
) -> Module {
  {
    hair_cache: Map::new(),
    draw_info: @types.BodyDrawInfo::new(bodynode, headnode),
    face_types: Map::new(),
    body_cache: Map::new(),
    char_look: None,
  }
}

///|
pub fn init_char_look(self : Module, entry : LookEntry) -> CharLook {
  let char_look = CharLook::new(entry, self) // TODO: support multi-player?
  self.char_look = Some(char_look)
  char_look
}

///|
pub fn get_player_char_look(self : Module) -> CharLook? {
  self.char_look
}

///|
pub fn get_body_draw_info(self : Module) -> @types.BodyDrawInfo {
  self.draw_info
}

///|
pub fn load_body_by_skin_id(
  self : Module,
  skin_id : Int
) -> @utils.Future[Body] {
  self.body_cache.get_or_init(
    skin_id,
    fn() { Body::load(skin_id, self.draw_info) },
  )
}

///|
pub fn load_hair_by_id(self : Module, hair_id : Int) -> @utils.Future[Hair] {
  self.hair_cache.get_or_init(
    hair_id,
    fn() { Hair::load(hair_id, self.draw_info) },
  )
}

///|
pub fn load_face_by_id(self : Module, face_id : Int) -> @utils.Future[Face] {
  self.face_types.get_or_init(face_id, fn() { Face::load(face_id) })
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, (@maple_stat.Id, @net.InPacket) -> Bool!] {
  [
    (
      @maple_stat.Id::SKIN,
      fn(_id, recv) {
        match self.char_look {
          Some(char_look) => char_look.set_body(recv.read_short!())
          None => ()
        }
        false
      },
    ),
    (
      @maple_stat.Id::FACE,
      fn(_id, recv) {
        match self.char_look {
          Some(char_look) => char_look.set_face(recv.read_int!())
          None => ()
        }
        false
      },
    ),
    (
      @maple_stat.Id::HAIR,
      fn(_id, recv) {
        match self.char_look {
          Some(char_look) => char_look.set_hair(recv.read_int!())
          None => ()
        }
        false
      },
    ),
  ]
  |> Map::from_array
}
