///|
using @quest {type QuestIconQueryResult, type QuestIconState}

///|
struct QuestIconResources {
  available : @resource.NxAnimation
  in_progress : @resource.NxAnimation
  completed : @resource.NxAnimation
}

///|
struct QuestIconContext {
  query_npc_icon : (Int) -> QuestIconQueryResult?
  build_quest_talk_args : (Int, Int) -> @npc.TalkArgs?
}

///|
struct QuestIconRuntime {
  oid : Int
  npc_id : Int
  quest_id : Int
  state : QuestIconState
  npc_entity : @entity.Entity
  npc_object : @physics.MovingObject
  icon_entity : @entity.Entity
  icon_offset : @struct.Point[Int]
  icon_size : @struct.Point[Int]
}

///|
let quest_icon_context : Ref[QuestIconContext?] = Ref::new(None)

///|
let quest_icon_resources : Ref[QuestIconResources?] = Ref::new(None)

///|
let quest_icon_loading : Ref[@utils.Future[Result[QuestIconResources, Error]]?] = Ref::new(
  None,
)

///|
let runtime_by_oid : Ref[Map[Int, QuestIconRuntime]] = Ref::new({})

///|
const QUEST_ICON_ZINDEX_OFFSET = 5000

///|
fn default_icon_offset() -> @struct.Point[Int] {
  @struct.Point::new(0, -96)
}

///|
/// Installs quest query callbacks consumed by `quest_icon_system`.
pub fn set_context(
  query_npc_icon : (Int) -> QuestIconQueryResult?,
  build_quest_talk_args : (Int, Int) -> @npc.TalkArgs?,
) -> Unit {
  quest_icon_context.val = Some({ query_npc_icon, build_quest_talk_args })
  ensure_resource_loading()
}

///|
/// Clears all quest-icon runtimes and detaches the current quest context.
pub fn clear_context() -> Unit {
  for _, runtime in runtime_by_oid.val {
    destroy_icon_entity(runtime.icon_entity)
  }
  runtime_by_oid.val.clear()
  quest_icon_context.val = None
}

///|
/// Overrides icon resources for tests to avoid async loader dependency.
pub fn set_resources_for_test(
  available : @resource.NxAnimation,
  in_progress : @resource.NxAnimation,
  completed : @resource.NxAnimation,
) -> Unit {
  quest_icon_resources.val = Some({ available, in_progress, completed })
  quest_icon_loading.val = None
}

///|
/// Runs quest-icon lifecycle, runtime sync, hit-test, and click dispatch.
pub fn quest_icon_system(_delta : Double) -> Unit {
  ensure_resource_loading()
  poll_loading_result()
  guard quest_icon_context.val is Some(context) else { return }
  guard quest_icon_resources.val is Some(resources) else { return }

  let anchors = @npc.list_npc_anchors()
  if not(anchors.is_empty()) {
    sync_runtimes(anchors, context, resources)
    if @quest.get_demo_quest_selection() is None {
      let npc_ids = anchors.map(fn(anchor) { anchor.npc_id })
      ignore(@quest.select_demo_quest_by_npcs(npc_ids))
    }
  }
  handle_cursor(context)
}

///|
/// Upserts one NPC quest-icon runtime directly.
///
/// Primarily used by tests; production uses `list_npc_anchors()` auto-sync.
pub fn upsert_npc(
  oid : Int,
  npc_id : Int,
  npc_entity : @entity.Entity,
  npc_object : @physics.MovingObject,
) -> Unit {
  guard quest_icon_context.val is Some(context) else { return }
  guard quest_icon_resources.val is Some(resources) else { return }
  upsert_runtime(
    { oid, npc_id, entity: npc_entity, npc_object },
    context,
    resources,
  )
}

///|
/// Removes one NPC quest-icon runtime by NPC object id.
pub fn remove_npc(oid : Int) -> Unit {
  remove_runtime(oid)
}

///|
/// Refresh hook for one quest update.
pub fn refresh_quest(_quest_id : Int) -> Unit {
  // event-driven refresh hook; current implementation refreshes every frame.
}

///|
/// Refresh hook for all quest-icon states.
pub fn refresh_all() -> Unit {
  // event-driven refresh hook; current implementation refreshes every frame.
}

///|
fn ensure_resource_loading() -> Unit {
  if quest_icon_resources.val is Some(_) || quest_icon_loading.val is Some(_) {
    return
  }
  quest_icon_loading.val = Some(
    @io_service.submit_background_task(async fn() { load_resources() }),
  )
}

///|
fn poll_loading_result() -> Unit {
  guard quest_icon_loading.val is Some(future) else { return }
  guard future.poll() is Some(rs) else { return }
  match rs {
    Ok(resources) => quest_icon_resources.val = Some(resources)
    Err(e) =>
      @log.error("failed to load quest icon resources", data={
        "error": e.to_string(),
      })
  }
  quest_icon_loading.val = None
}

///|
async fn load_resources() -> QuestIconResources {
  let loader = @resource.get_ui_window_2_loader()
  let available_json = loader.load_resource(["QuestIcon", "0"])
  let inprogress_json = loader.load_resource(["QuestIcon", "1"])
  let completed_json = loader.load_resource(["QuestIcon", "2"])
  {
    available: @json.from_json(available_json),
    in_progress: @json.from_json(inprogress_json),
    completed: @json.from_json(completed_json),
  }
}

///|
fn sync_runtimes(
  anchors : Array[@npc.NpcAnchor],
  context : QuestIconContext,
  resources : QuestIconResources,
) -> Unit {
  let seen_oids : Map[Int, Unit] = {}
  for anchor in anchors {
    seen_oids.set(anchor.oid, ())
    upsert_runtime(anchor, context, resources)
  }
  let removed = []
  for oid, _ in runtime_by_oid.val {
    if not(seen_oids.contains(oid)) {
      removed.push(oid)
    }
  }
  for oid in removed {
    remove_runtime(oid)
  }
}

///|
fn upsert_runtime(
  anchor : @npc.NpcAnchor,
  context : QuestIconContext,
  resources : QuestIconResources,
) -> Unit {
  let oid = anchor.oid
  let desired = (context.query_npc_icon)(anchor.npc_id)
  guard desired is Some(desired) else {
    remove_runtime(oid)
    return
  }

  let should_replace = match runtime_by_oid.val.get(oid) {
    Some(runtime) =>
      runtime.quest_id != desired.quest_id ||
      runtime.state != desired.state ||
      not(runtime.icon_entity.is_alive())
    None => true
  }

  if should_replace {
    remove_runtime(oid)
    let icon = state_to_icon(resources, desired.state)
    let icon_entity = anchor.entity.spawn_child(
      offset=@selene_math.Vec2D(
        default_icon_offset().x.to_double(),
        default_icon_offset().y.to_double(),
      ),
    )
    let icon_animation = @resource.nx_animation_to_selene_animation(
      icon,
      loop_=true,
    )
    @sprite.sprites.set(
      icon_entity,
      @sprite.Sprite::from_animation(
        icon_animation,
        @graphics.OBJECT_TILE_LAYER_ZINDEX + QUEST_ICON_ZINDEX_OFFSET,
      ),
    )
    runtime_by_oid.val.set(oid, {
      oid,
      npc_id: anchor.npc_id,
      quest_id: desired.quest_id,
      state: desired.state,
      npc_entity: anchor.entity,
      npc_object: anchor.npc_object,
      icon_entity,
      icon_offset: default_icon_offset(),
      icon_size: nx_animation_dimensions(icon),
    })
  } else if runtime_by_oid.val.get(oid) is Some(runtime) {
    runtime_by_oid.val.set(oid, {
      ..runtime,
      npc_entity: anchor.entity,
      npc_object: anchor.npc_object,
    })
  }
}

///|
fn remove_runtime(oid : Int) -> Unit {
  if runtime_by_oid.val.get(oid) is Some(runtime) {
    destroy_icon_entity(runtime.icon_entity)
    runtime_by_oid.val.remove(oid)
  }
}

///|
fn handle_cursor(context : QuestIconContext) -> Unit {
  let mouse_pos = @inputs.mouse.pos
  let cursor_pos = @struct.Point::new(
    mouse_pos[@selene_math.X].to_int(),
    mouse_pos[@selene_math.Y].to_int(),
  )
  let camera_pos = @camera.get_position()
  let view_pos = @struct.Point::new(
    -camera_pos[@selene_math.X].to_int(),
    -camera_pos[@selene_math.Y].to_int(),
  )
  let pressed = @inputs.is_mouse_just_pressed(@inputs.MouseButton::Left)
  for _, runtime in runtime_by_oid.val {
    if inrange(runtime, cursor_pos, view_pos) {
      if pressed {
        if (context.build_quest_talk_args)(runtime.quest_id, runtime.npc_id)
          is Some(args) {
          @npc.request_quest_talk(args)
          @npc.claim_click_this_frame()
          return
        }
        return
      }
      @cursor.request_cursor_state(@ui.CursorState::CAN_CLICK)
      return
    }
  }
}

///|
fn inrange(
  runtime : QuestIconRuntime,
  cursor_pos : @struct.Point[Int],
  view_pos : @struct.Point[Int],
) -> Bool {
  let abs = runtime.npc_object.get_position() + runtime.icon_offset + view_pos
  let dim = runtime.icon_size
  @struct.Rectangle::from4(
    abs.x - dim.x / 2,
    abs.x + dim.x / 2,
    abs.y - dim.y,
    abs.y,
  ).contains(cursor_pos)
}

///|
fn state_to_icon(
  resources : QuestIconResources,
  state : QuestIconState,
) -> @resource.NxAnimation {
  match state {
    @quest.QuestIconState::AVAILABLE => resources.available
    @quest.QuestIconState::IN_PROGRESS => resources.in_progress
    @quest.QuestIconState::COMPLETED => resources.completed
  }
}

///|
fn destroy_icon_entity(icon_entity : @entity.Entity) -> Unit {
  @sprite.sprites.remove(icon_entity)
  icon_entity.destroy()
}

///|
fn nx_animation_dimensions(
  animation : @resource.NxAnimation,
) -> @struct.Point[Int] {
  let mut width = 0
  let mut height = 0
  for frame in animation.frames {
    width = @cmp.maximum(width, frame.texture.w)
    height = @cmp.maximum(height, frame.texture.h)
  }
  @struct.Point::new(width, height)
}
