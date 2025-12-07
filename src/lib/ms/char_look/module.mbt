///|
struct Module {
  draw_info : @types.BodyDrawInfo
  hair_cache : Map[Int, Hair]
  face_types : Map[Int, Face]
  body_cache : Map[Int, FullBody]
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit
}

///|
pub async fn Module::load(
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
) -> Module {
  // let bodynode = get_body_loader().load_res_async(["00002000.img"])
  // let headnode = get_body_loader().load_res_async(["00012000.img"])
  Module::new(on_player_look_changed)
}

///|
pub fn Module::new(
  on_player_look_changed : ((CharLook) -> CharLook) -> Unit,
) -> Module raise {
  {
    hair_cache: Map::new(),
    draw_info: get_draw_info(),
    face_types: Map::new(),
    body_cache: Map::new(),
    on_player_look_changed,
  }
}

///|
pub async fn Module::load_char_look(
  self : Module,
  entry : LookEntry,
) -> CharLook {
  // let body = self.load_body_by_skin_id(entry.skin)
  // let hair = self.load_hair_by_id(entry.hairid)
  // let face = self.load_face_by_id(entry.faceid)
  // CharLook::load(entry, body, hair, face, self.draw_info)
  ...
}

///|
pub async fn Module::load_body_by_skin_id(
  self : Module,
  skin_id : Int,
) -> FullBody {
  guard skin_id == 0 else { fail("only support default skin for now") }
  let body = FullBody::new(
    skin_id,
    self.draw_info,
    get_stance_bodys_map(),
    get_stance_heads_map(),
  )
  self.body_cache.set(skin_id, body)
  body
}

///|
pub async fn Module::load_hair_by_id(self : Module, hair_id : Int) -> Hair {
  let hair = Hair::load(hair_id, self.draw_info)
  self.hair_cache.set(hair_id, hair)
  hair
}

///|
pub async fn Module::load_face_by_id(self : Module, face_id : Int) -> Face {
  let face = Face::load(face_id)
  self.face_types.set(face_id, face)
  face
}

///|
pub fn Module::make_stat_handlers(
  self : Module,
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
        @io_service.execute_background(fn() {
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
        @io_service.execute_background(fn() {
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
        @io_service.execute_background(fn() {
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

// let     draw_info: @types.BodyDrawInfo::new(bodynode, headnode),

///|
let draw_info : Ref[@types.BodyDrawInfo?] = Ref::new(None)

///|
let stance_bodys_map : Ref[NxStanceLooks[@types.NxStanceBody]?] = Ref::new(None)

///|
let stance_heads_map : Ref[NxStanceLooks[@types.NxLayerTextures]?] = Ref::new(
  None,
)

///|
pub fn get_stance_bodys_map() -> Map[
  @types.StanceId,
  Array[@types.NxStanceBody],
] raise {
  match stance_bodys_map.val {
    Some(v) => v.0
    None => {
      let v = @json.from_json(bodynode)
      stance_bodys_map.val = Some(v)
      v.0
    }
  }
}

///|
pub fn get_stance_heads_map() -> Map[
  @types.StanceId,
  Array[@types.NxLayerTextures],
] raise {
  match stance_heads_map.val {
    Some(v) => v.0
    None => {
      let v = @json.from_json(headnode)
      stance_heads_map.val = Some(v)
      v.0
    }
  }
}

///|
pub fn get_draw_info() -> @types.BodyDrawInfo raise {
  match draw_info.val {
    Some(v) => v
    None => {
      let bodynode : NxStanceLooks[@types.NxStanceBody] = get_stance_bodys_map()
      let headnode : NxStanceLooks[@types.NxLayerTextures] = get_stance_heads_map()
      let v = @types.BodyDrawInfo::new(bodynode.0, headnode.0)
      draw_info.val = Some(v)
      v
    }
  }
}

///|
pub(all) struct NxStanceLooks[T](Map[@types.StanceId, Array[T]])

///|
pub impl[T : @json.FromJson] @json.FromJson for NxStanceLooks[T] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = Map::new()
  for k, v in obj {
    guard @types.StanceId::from_name(k) is Some(stance_id) else { continue }
    let nodes : Array[T] = @resource.parse_map_based_array(
      v,
      path=path.add_key(k),
    )
    map.set(stance_id, nodes)
  }
  map
}
