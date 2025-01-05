///|
struct Module {
  draw_info : @types.BodyDrawInfo
  hair_cache : Map[Int, @utils.Future[Hair]]
  face_types : Map[Int, @utils.Future[Face]]
  body_cache : Map[Int, @utils.Future[Body]]
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit
  io_service : @io_task.Service
}

///|
pub fn Module::load(
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
  io_service : @io_task.Service
) -> @utils.Future[Module] {
  let bodynode = get_body_loader().load_res(["00002000.img"])
  let headnode = get_body_loader().load_res(["00012000.img"])
  bodynode
  .combine(headnode)
  .map(fn(it) {
    let (bodynode, headnode) = it
    Module::new(bodynode, headnode, on_player_look_changed, io_service)
  })
}

///|
pub fn Module::new(
  bodynode : @resource.NxNode,
  headnode : @resource.NxNode,
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
  io_service : @io_task.Service
) -> Module {
  {
    hair_cache: Map::new(),
    draw_info: @types.BodyDrawInfo::new?(bodynode.value(), headnode.value()).unwrap(), // TODO
    face_types: Map::new(),
    body_cache: Map::new(),
    on_player_look_changed,
    io_service,
  }
}

///|
pub fn load_char_look(
  self : Module,
  entry : LookEntry
) -> @utils.Future[CharLook] {
  let body = self.load_body_by_skin_id(entry.skin)
  let hair = self.load_hair_by_id(entry.hairid)
  let face = self.load_face_by_id(entry.faceid)
  body
  .combine(hair)
  .combine(face)
  .map(fn(it) {
    let ((body, hair), face) = it
    CharLook::new(entry, body, hair, face, self.draw_info)
  })
}

///|
pub fn load_body_by_skin_id(
  self : Module,
  skin_id : Int
) -> @utils.Future[Body] {
  self.body_cache.get_or_init(skin_id, fn() {
    Body::load(skin_id, self.draw_info)
  })
}

///|
pub fn load_hair_by_id(self : Module, hair_id : Int) -> @utils.Future[Hair] {
  self.hair_cache.get_or_init(hair_id, fn() {
    Hair::load(hair_id, self.draw_info)
  })
}

///|
pub fn load_face_by_id(self : Module, face_id : Int) -> @utils.Future[Face] {
  self.face_types.get_or_init(face_id, fn() { Face::load(face_id) })
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
  struct ChangeLookActorState {
    mut changing_skin_id : Int?
    mut changing_face_id : Int?
    mut changing_hair_id : Int?
  } derive(Default)
  let state = ChangeLookActorState::default()
  [
    (
      @maple_stat.Id::SKIN,
      fn(skin_id) {
        let f = self.load_body_by_skin_id(skin_id)
        state.changing_skin_id = Some(skin_id)
        self.io_service.on_complete(f, fn(body) {
          guard state.changing_skin_id == Some(skin_id) else { return }
          state.changing_skin_id = None
          (self.on_player_look_changed)(fn(char_look) {
            char_look.change_body(body)
          })
        })
        false
      },
    ),
    (
      @maple_stat.Id::FACE,
      fn(face_id) {
        let f = self.load_face_by_id(face_id)
        state.changing_face_id = Some(face_id)
        self.io_service.on_complete(f, fn(face) {
          guard state.changing_face_id == Some(face_id) else { return }
          state.changing_face_id = None
          (self.on_player_look_changed)(fn(char_look) {
            char_look.change_face(face)
          })
        })
        false
      },
    ),
    (
      @maple_stat.Id::HAIR,
      fn(hair_id) {
        let f = self.load_hair_by_id(hair_id)
        state.changing_hair_id = Some(hair_id)
        self.io_service.on_complete(f, fn(hair) {
          guard state.changing_hair_id == Some(hair_id) else { return }
          state.changing_hair_id = None
          (self.on_player_look_changed)(fn(char_look) {
            char_look.change_hair(hair)
          })
        })
        false
      },
    ),
  ]
  |> Map::from_array
}
