///|
priv struct QuestIconResources {
  available : @resource.NxAnimation
  in_progress : @resource.NxAnimation
  completed : @resource.NxAnimation
}

///|
priv struct QuestIconContext {
  query_npc_icon : (Int) -> QuestIconQueryResult?
  get_query_revision : () -> Int
}

///|
priv struct QuestIconRuntime {
  _oid : Int
  npc_id : Int
  quest_id : Int
  state : QuestIconState
  _npc_entity : @entity.Entity
  npc_object : @physics.MovingObject
  icon_entity : @entity.Entity
  icon_offset : @struct.Point[Int]
  icon_size : @struct.Point[Int]
}

///|
let quest_icon_resources : Ref[QuestIconResources?] = Ref::new(None)

///|
let quest_icon_loading : Ref[@utils.Future[Result[QuestIconResources, Error]]?] = Ref::new(
  None,
)

///|
let runtime_by_oid : Ref[Map[Int, QuestIconRuntime]] = Ref::new({})

///|
let npc_icon_cache : Ref[Map[Int, CachedNpcIconQuery]] = Ref::new({})

///|
priv struct CachedNpcIconQuery {
  revision : Int
  result : QuestIconQueryResult?
}

///|
let last_quest_log_revision : Ref[Int] = Ref::new(-1)

///|
const QUEST_ICON_ZINDEX_OFFSET = 5000

///|
fn default_icon_offset() -> @struct.Point[Int] {
  @struct.Point::new(0, -96)
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
pub fn quest_icon_system(_world : @ecs.World) -> Unit {
  ensure_resource_loading()
  poll_loading_result()
  guard quest_icon_resources.val is Some(resources) else { return }
  let quest_log_rev = @quest_log.revision()
  if quest_log_rev != last_quest_log_revision.val {
    if @player.get_player() is Some(player) {
      bind_player(player)
      last_quest_log_revision.val = quest_log_rev
    }
  }
  let inventory_events = @inventory.inventory_changed_event_bus.read(
    get_inventory_changed_reader(),
  )
  let char_stat_events = @char_stats.char_stats_changed_event_bus.read(
    get_char_stats_changed_reader(),
  )
  if !inventory_events.is_empty() || !char_stat_events.is_empty() {
    bump_quest_icon_query_revision()
  }

  let context = {
    query_npc_icon,
    get_query_revision: quest_icon_query_revision,
  }
  let anchors = @npc.list_npc_anchors()
  if !anchors.is_empty() {
    sync_runtimes(anchors, context, resources)
    if get_demo_quest_selection() is None {
      let npc_ids = anchors.map(fn(anchor) { anchor.npc_id })
      ignore(select_demo_quest_by_npcs(npc_ids))
    }
  }
  handle_pointer_clicks()
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
  guard quest_icon_resources.val is Some(resources) else { return }

  let context = {
    query_npc_icon,
    get_query_revision: quest_icon_query_revision,
  }
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
  let loader = @resource.require_async_loader("ui_window_2")
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
    if !seen_oids.contains(oid) {
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
  let desired = query_npc_icon_cached(anchor.npc_id, context)
  guard desired is Some(desired) else {
    remove_runtime(oid)
    return
  }

  let should_replace = match runtime_by_oid.val.get(oid) {
    Some(runtime) =>
      runtime.quest_id != desired.quest_id ||
      runtime.state != desired.state ||
      !runtime.icon_entity.is_alive()
    None => true
  }

  if should_replace {
    let previous = runtime_by_oid.val.get(oid)
    remove_runtime(oid)
    let icon = state_to_icon(resources, desired.state)
    let icon_size = nx_animation_dimensions(icon)
    let icon_entity = anchor.entity.spawn_child()
    @transform2d.set_xy(
      icon_entity,
      @selene_math.Vec2(
        default_icon_offset().x.to_double(),
        default_icon_offset().y.to_double(),
      ),
    )
    let icon_animation = @ms_animation.from_nx_animation(icon, loop_=true)
    @sprite.sprites().set(
      icon_entity,
      @ms_animation.sprite_from_animation(
        icon_animation,
        @graphics.OBJECT_TILE_LAYER_ZINDEX + QUEST_ICON_ZINDEX_OFFSET,
      ),
    )
    @physics2d.pickables().set(icon_entity, @physics2d.Pickable::new())
    @physics2d.shapes().set(
      icon_entity,
      @physics2d.CollisionShape::Rect(
        size=@selene_math.Vec2(icon_size.x.to_double(), icon_size.y.to_double()),
        offset=@selene_math.Vec2(
          -icon_size.x.to_double() / 2.0,
          -icon_size.y.to_double(),
        ),
      ),
    )
    runtime_by_oid.val.set(oid, {
      _oid: oid,
      npc_id: anchor.npc_id,
      quest_id: desired.quest_id,
      state: desired.state,
      _npc_entity: anchor.entity,
      npc_object: anchor.npc_object,
      icon_entity,
      icon_offset: default_icon_offset(),
      icon_size,
    })
    if previous is Some(runtime) {
      @log.debug("quest icon state changed", data={
        "npc_id": anchor.npc_id,
        "from_quest_id": runtime.quest_id,
        "to_quest_id": desired.quest_id,
        "from_state": runtime.state,
        "to_state": desired.state,
      })
    } else {
      @log.debug("quest icon shown", data={
        "npc_id": anchor.npc_id,
        "quest_id": desired.quest_id,
        "state": desired.state,
      })
    }
  } else if runtime_by_oid.val.get(oid) is Some(runtime) {
    runtime_by_oid.val.set(oid, {
      ..runtime,
      _npc_entity: anchor.entity,
      npc_object: anchor.npc_object,
    })
  }
}

///|
fn remove_runtime(oid : Int) -> Unit {
  if runtime_by_oid.val.get(oid) is Some(runtime) {
    destroy_icon_entity(runtime.icon_entity)
    npc_icon_cache.val.remove(runtime.npc_id)
    runtime_by_oid.val.remove(oid)
  }
}

///|
fn query_npc_icon_cached(
  npc_id : Int,
  context : QuestIconContext,
) -> QuestIconQueryResult? {
  let revision = (context.get_query_revision)()
  match npc_icon_cache.val.get(npc_id) {
    Some(cached) if cached.revision == revision => cached.result
    _ => {
      let result = (context.query_npc_icon)(npc_id)
      npc_icon_cache.val.set(npc_id, { revision, result })
      result
    }
  }
}

///|
fn handle_pointer_clicks() -> Unit {
  if @npc_talk_ui.is_npc_talk_ui_open() {
    return
  }
  let events = @physics2d.pointer_event_bus.read(get_pointer_event_reader())
  for event in events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    guard event.phase is @physics2d.PointerPhase::JustPressed else { continue }
    guard find_runtime_by_icon_entity(event.entity) is Some(runtime) else {
      continue
    }
    if build_quest_talk_args(runtime.quest_id, runtime.npc_id) is Some(args) {
      @npc.request_quest_talk(args)
      return
    }
  }
}

///|
fn state_to_icon(
  resources : QuestIconResources,
  state : QuestIconState,
) -> @resource.NxAnimation {
  match state {
    QuestIconState::AVAILABLE => resources.available
    QuestIconState::IN_PROGRESS => resources.in_progress
    QuestIconState::COMPLETED => resources.completed
  }
}

///|
fn destroy_icon_entity(icon_entity : @entity.Entity) -> Unit {
  @physics2d.pickables().remove(icon_entity)
  @physics2d.shapes().remove(icon_entity)
  @sprite.sprites().remove(icon_entity)
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

///|
using @lazy {type Lazy}

///|
let inventory_changed_reader_ref : Lazy[
  @event.EventReader[@inventory.InventoryChangedEvent],
] = Lazy::new(fn() { @event.EventReader::new() })

///|
fn get_inventory_changed_reader() -> @event.EventReader[
  @inventory.InventoryChangedEvent,
] {
  inventory_changed_reader_ref.get()
}

///|
fn get_char_stats_changed_reader() -> @event.EventReader[
  @char_stats.CharStatsChangedEvent,
] {
  char_stats_changed_reader_ref.get()
}

///|
let char_stats_changed_reader_ref : Lazy[
  @event.EventReader[@char_stats.CharStatsChangedEvent],
] = Lazy::new(fn() { @event.EventReader::new() })

///|
let pointer_event_reader_ref : Lazy[@event.EventReader[@physics2d.PointerEvent]] = Lazy::new(fn() {
    @event.EventReader::new()
  },
)

///|
fn get_pointer_event_reader() -> @event.EventReader[@physics2d.PointerEvent] {
  pointer_event_reader_ref.get()
}

///|
fn find_runtime_by_icon_entity(entity : @entity.Entity) -> QuestIconRuntime? {
  for _, runtime in runtime_by_oid.val {
    if runtime.icon_entity == entity {
      return Some(runtime)
    }
  }
  None
}
