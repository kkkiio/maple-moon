///|
using @resource {get_body_loader}

///|
using @utils {type Future}

///|
using @io_service {submit_background_task}

///|
pub struct CharLookMod {
  draw_info : @types.BodyDrawInfo
  stance_bodys_map : NxStanceLooks[@types.NxStanceBody]
  stance_heads_map : NxStanceLooks[@types.NxLayerTextures]
  hair_cache : Map[Int, Hair]
  face_types : Map[Int, Face]
  body_cache : Map[Int, FullBody]
}

///|
pub async fn CharLookMod::load() -> CharLookMod {
  let stance_bodys_map = load_stance_bodys_map()
  let stance_heads_map = load_stance_heads_map()
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  CharLookMod::new(stance_bodys_map, stance_heads_map, draw_info)
}

///|
pub fn CharLookMod::new(
  stance_bodys_map : NxStanceLooks[@types.NxStanceBody],
  stance_heads_map : NxStanceLooks[@types.NxLayerTextures],
  draw_info : @types.BodyDrawInfo,
) -> CharLookMod {
  {
    hair_cache: Map::new(),
    draw_info,
    stance_bodys_map,
    stance_heads_map,
    face_types: Map::new(),
    body_cache: Map::new(),
  }
}

///|
let mod : Ref[CharLookMod?] = Ref::new(None)

///|
pub fn get_module() -> CharLookMod? {
  mod.val
}

///|
let loading_mod_future : Ref[Future[Result[CharLookMod, Error]]?] = Ref::new(
  None,
)

///|
/// Load char look module if not loaded yet.
pub fn char_look_system(_delta : Double) -> Unit {
  if mod.val is Some(_) {
    return
  }
  guard loading_mod_future.val is Some(fut) else {
    loading_mod_future.val = Some(submit_background_task(CharLookMod::load))
    return
  }
  guard fut.poll() is Some(res) else { return }
  match res {
    Ok(m) => mod.val = Some(m)
    Err(e) => abort("loading char look module failed, error=\{e}")
  }
}

///|
pub async fn CharLookMod::load_char_look(
  self : CharLookMod,
  entry : LookEntry,
) -> CharLook {
  // let body = self.load_body_by_skin_id(entry.skin)
  // let hair = self.load_hair_by_id(entry.hairid)
  // let face = self.load_face_by_id(entry.faceid)
  // CharLook::load(entry, body, hair, face, self.draw_info)
  ...
}

///|
pub async fn CharLookMod::load_body_by_skin_id(
  self : CharLookMod,
  skin_id : Int,
) -> FullBody {
  guard skin_id == 0 else { fail("only support default skin for now") }
  let body = FullBody::new(
    skin_id,
    self.draw_info,
    self.stance_bodys_map.0,
    self.stance_heads_map.0,
  )
  self.body_cache.set(skin_id, body)
  body
}

///|
pub async fn CharLookMod::load_hair_by_id(
  self : CharLookMod,
  hair_id : Int,
) -> Hair {
  let hair = Hair::load(hair_id, self.draw_info)
  self.hair_cache.set(hair_id, hair)
  hair
}

///|
pub async fn CharLookMod::load_face_by_id(
  self : CharLookMod,
  face_id : Int,
) -> Face {
  let face = Face::load(face_id)
  self.face_types.set(face_id, face)
  face
}

// ///|
// pub fn Module::make_stat_handlers(
//   self : Module,
// ) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
//   struct ChangeLookActorState {
//     mut changing_skin_id : Int?
//     mut changing_face_id : Int?
//     mut changing_hair_id : Int?
//   } derive(Default)
//   let state = ChangeLookActorState::default()
//   [
//     (
//       @maple_stat.Id::SKIN,
//       fn(skin_id) {
//         state.changing_skin_id = Some(skin_id)
//         @io_service.execute_background(fn() {
//           let body = self.load_body_by_skin_id(skin_id)
//           guard state.changing_skin_id == Some(skin_id) else { return }
//           state.changing_skin_id = None
//           (self.on_player_look_changed)(fn(char_look) {
//             char_look.change_body(body)
//           })
//         })
//         false
//       },
//     ),
//     (
//       @maple_stat.Id::FACE,
//       fn(face_id) {
//         state.changing_face_id = Some(face_id)
//         @io_service.execute_background(fn() {
//           let face = self.load_face_by_id(face_id)
//           guard state.changing_face_id == Some(face_id) else { return }
//           state.changing_face_id = None
//           (self.on_player_look_changed)(fn(char_look) {
//             char_look.change_face(face)
//           })
//         })
//         false
//       },
//     ),
//     (
//       @maple_stat.Id::HAIR,
//       fn(hair_id) {
//         state.changing_hair_id = Some(hair_id)
//         @io_service.execute_background(fn() {
//           let hair = self.load_hair_by_id(hair_id)
//           guard state.changing_hair_id == Some(hair_id) else { return }
//           state.changing_hair_id = None
//           (self.on_player_look_changed)(fn(char_look) {
//             char_look.change_hair(hair)
//           })
//         })
//         false
//       },
//     ),
//   ]
//   |> Map::from_array
// }

///|
async fn load_stance_bodys_map() -> NxStanceLooks[@types.NxStanceBody] {
  let bodynode = get_body_loader().load_res_async(["00002000.img"]).value()
  let v : NxStanceLooks[@types.NxStanceBody] = @json.from_json(bodynode)
  v
}

///|
async fn load_stance_heads_map() -> NxStanceLooks[@types.NxLayerTextures] {
  let headnode = get_body_loader().load_res_async(["00012000.img"]).value()
  let v : NxStanceLooks[@types.NxLayerTextures] = @json.from_json(headnode)
  v
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
