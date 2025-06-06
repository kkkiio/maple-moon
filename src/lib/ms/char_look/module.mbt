///|
struct Module {
  io_service : @io_task.IOService
  string_loader : @resource.SyncLoader
  draw_info : @types.BodyDrawInfo
  hair_cache : Map[Int, Hair]
  face_types : Map[Int, Face]
  body_cache : Map[Int, Body]
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit
}

///|
pub fn Module::load(
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
  io_service : @io_task.IOService,
  string_loader : @resource.SyncLoader
) -> @utils.Future[Module] {
  let bodynode = get_body_loader().load_res(["00002000.img"])
  let headnode = get_body_loader().load_res(["00012000.img"])
  bodynode
  .combine(headnode)
  .map(fn(it) {
    let (bodynode, headnode) = it
    Module::new(
      bodynode, headnode, on_player_look_changed, io_service, string_loader,
    )
  })
}

///|
pub fn Module::new(
  bodynode : @resource.NxNode,
  headnode : @resource.NxNode,
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
  io_service : @io_task.IOService,
  string_loader : @resource.SyncLoader
) -> Module {
  {
    hair_cache: Map::new(),
    string_loader,
    draw_info: @types.BodyDrawInfo::new?(bodynode.value(), headnode.value()).unwrap(), // TODO
    face_types: Map::new(),
    body_cache: Map::new(),
    on_player_look_changed,
    io_service,
  }
}

///|
pub async fn load_char_look(self : Module, entry : LookEntry) -> CharLook! {
  let body = self.load_body_by_skin_id(entry.skin)
  let hair = self.load_hair_by_id(entry.hairid)
  let face = self.load_face_by_id(entry.faceid)
  CharLook::new(entry, body, hair, face, self.string_loader, self.draw_info)
}

///|
pub async fn load_body_by_skin_id(self : Module, skin_id : Int) -> Body! {
  let body = Body::load(skin_id, self.draw_info)
  self.body_cache.set(skin_id, body)
  body
}

///|
pub async fn load_hair_by_id(self : Module, hair_id : Int) -> Hair! {
  let hair = Hair::load(hair_id, self.draw_info, self.string_loader)
  self.hair_cache.set(hair_id, hair)
  hair
}

///|
pub async fn load_face_by_id(self : Module, face_id : Int) -> Face! {
  let face = Face::load(face_id, self.string_loader)
  self.face_types.set(face_id, face)
  face
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
        state.changing_skin_id = Some(skin_id)
        self.io_service.execute(async fn() {
          let body = self.load_body_by_skin_id(skin_id)
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
        state.changing_face_id = Some(face_id)
        self.io_service.execute(async fn() {
          let face = self.load_face_by_id(face_id)
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
        state.changing_hair_id = Some(hair_id)
        self.io_service.execute(async fn() {
          let hair = self.load_hair_by_id(hair_id)
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
