///|
using @types {type NxStanceLooks}

///|
pub struct CharacterPresentationResource {
  draw_info : @types.BodyDrawInfo
  stance_bodys_map : NxStanceLooks[@types.NxStanceBody]
  stance_heads_map : NxStanceLooks[@types.NxMultiPartFrame]
  hair_cache : Map[Int, Hair]
  face_types : Map[Int, Face]
  body_cache : Map[Int, FullBody]
}

///|
pub fn CharacterPresentationResource::load() -> CharacterPresentationResource {
  let stance_bodys_map = load_stance_bodys_map()
  let stance_heads_map = load_stance_heads_map()
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  CharacterPresentationResource::new(
    stance_bodys_map, stance_heads_map, draw_info,
  )
}

///|
pub fn CharacterPresentationResource::new(
  stance_bodys_map : NxStanceLooks[@types.NxStanceBody],
  stance_heads_map : NxStanceLooks[@types.NxMultiPartFrame],
  draw_info : @types.BodyDrawInfo,
) -> CharacterPresentationResource {
  {
    hair_cache: Map([]),
    draw_info,
    stance_bodys_map,
    stance_heads_map,
    face_types: Map([]),
    body_cache: Map([]),
  }
}

///|
let resources_by_world : Ref[Map[UInt, CharacterPresentationResource]] = Ref(
  Map([]),
)

///|
pub fn get_resource() -> CharacterPresentationResource? {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val.get(world_id)
}

///|
/// Insert character presentation resource for the current world.
pub fn insert_resource(resource : CharacterPresentationResource) -> Unit {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val[world_id] = resource
}

///|
/// Clear character presentation resource for the current world.
pub fn clear_resource() -> Unit {
  let world_id = @ecs.require_current_world().id()
  resources_by_world.val.remove(world_id)
}

///|
/// Character presentation runtime update system.
pub fn char_look_system(_world : @ecs.World) -> Unit {
  char_look_animation_tick_system(_world)
  char_look_layer_system(_world)
}

///|
pub fn CharacterPresentationResource::load_body_by_skin_id(
  self : CharacterPresentationResource,
  skin_id : Int,
) -> FullBody {
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
pub fn CharacterPresentationResource::load_hair_by_id(
  self : CharacterPresentationResource,
  hair_id : Int,
) -> Hair {
  let hair = Hair::load(hair_id, self.draw_info)
  self.hair_cache.set(hair_id, hair)
  hair
}

///|
pub fn CharacterPresentationResource::load_face_by_id(
  self : CharacterPresentationResource,
  face_id : Int,
) -> Face {
  let face = Face::load(face_id)
  self.face_types.set(face_id, face)
  face
}

///|
/// Backward-compatible alias for migration.
pub fn get_module() -> CharacterPresentationResource? {
  get_resource()
}

///|
/// Backward-compatible alias for migration.
pub fn set_module(resource : CharacterPresentationResource) -> Unit {
  insert_resource(resource)
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
fn load_stance_bodys_map() -> NxStanceLooks[@types.NxStanceBody] {
  let bodynode = @resource.require_json(
    "assets/Character/Body/00002000.img.json",
  )
  let v : NxStanceLooks[@types.NxStanceBody] = @json.from_json(bodynode) catch {
    err => abort("failed to decode body stance map: \{err}")
  }
  v
}

///|
fn load_stance_heads_map() -> NxStanceLooks[@types.NxMultiPartFrame] {
  let headnode = @resource.require_json(
    "assets/Character/Body/00012000.img.json",
  )
  let v : NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(headnode) catch {
    err => abort("failed to decode head stance map: \{err}")
  }
  v
}
