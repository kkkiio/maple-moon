///|
using @server_proto {type MobHpMessage}

///|
priv struct MobHpEvent {
  oid : Int
  percent : Int
  player_level : Int
}

///|
priv struct MobHpBarState {
  root : @entity.Entity
  fill_light : @entity.Entity
  fill_dark : @entity.Entity
  mut percent : Int
  mut ttl_ms : Double
}

///|
let hp_events : @queue.Queue[MobHpEvent] = @queue.new()

///|
let hp_states : Map[Int, MobHpBarState] = Map::new()

///|
const HP_BAR_WIDTH : Int = 50

///|
const HP_BAR_HEIGHT : Int = 10

///|
const HP_BAR_TOP_SHIFT : Int = -30

///|
fn hp_fill_width(percent : Int) -> Double {
  let clamped = percent |> @cmp.maximum(0) |> @cmp.minimum(100)
  ((HP_BAR_WIDTH - 6).to_double() * clamped.to_double() / 100.0)
  .to_int()
  .to_double()
}

///|
fn set_rect_sprite(
  entity : @entity.Entity,
  width : Double,
  height : Double,
  color : String,
) -> Unit {
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_color(
      @sprite.color_from_css(color),
      @selene_math.Vec2(width, height),
    ),
  )
  if @transform.transforms().get(entity) is Some(current) {
    @transform.transforms().set(entity, {
      ..current,
      translation: @selene_math.Vec3::new(
        current.translation.x,
        current.translation.y,
        @graphics.MOB_HP_BAR_ZINDEX.to_double(),
      ),
    })
  } else {
    @transform.transforms().set(
      entity,
      @transform.Transform::from_xyz(
        0.0,
        0.0,
        @graphics.MOB_HP_BAR_ZINDEX.to_double(),
      ),
    )
  }
}

///|
fn upsert_fill_sprite(state : MobHpBarState) -> Unit {
  let fill_width = hp_fill_width(state.percent)
  set_rect_sprite(state.fill_light, fill_width, 3.0, "rgba(0, 255, 0, 1)")
  set_rect_sprite(state.fill_dark, fill_width, 1.0, "rgba(0, 128, 0, 1)")
}

///|
fn create_hpbar_state(parent : @entity.Entity) -> MobHpBarState {
  fn spawn_child_at(
    parent : @entity.Entity,
    offset : @selene_math.Vec2,
  ) -> @entity.Entity {
    let child = parent.spawn_child()
    @transform2d.set_xy(child, offset)
    child
  }
  let root = parent.spawn_child()
  let frame_bg = spawn_child_at(
    root,
    @selene_math.Vec2((-HP_BAR_WIDTH / 2).to_double(), 0.0),
  )
  let frame_top = spawn_child_at(
    root,
    @selene_math.Vec2((1 - HP_BAR_WIDTH / 2).to_double(), 1.0),
  )
  let frame_bottom = spawn_child_at(
    root,
    @selene_math.Vec2(
      (1 - HP_BAR_WIDTH / 2).to_double(),
      (HP_BAR_HEIGHT - 2).to_double(),
    ),
  )
  let frame_left = spawn_child_at(
    root,
    @selene_math.Vec2((1 - HP_BAR_WIDTH / 2).to_double(), 2.0),
  )
  let frame_right = spawn_child_at(
    root,
    @selene_math.Vec2((HP_BAR_WIDTH - 2 - HP_BAR_WIDTH / 2).to_double(), 2.0),
  )
  let fill_light = spawn_child_at(
    root,
    @selene_math.Vec2((3 - HP_BAR_WIDTH / 2).to_double(), 3.0),
  )
  let fill_dark = spawn_child_at(
    root,
    @selene_math.Vec2((3 - HP_BAR_WIDTH / 2).to_double(), 6.0),
  )

  set_rect_sprite(
    frame_bg,
    HP_BAR_WIDTH.to_double(),
    HP_BAR_HEIGHT.to_double(),
    "rgba(0, 0, 0, 1)",
  )
  set_rect_sprite(
    frame_top,
    (HP_BAR_WIDTH - 2).to_double(),
    1.0,
    "rgba(255, 255, 255, 1)",
  )
  set_rect_sprite(
    frame_bottom,
    (HP_BAR_WIDTH - 2).to_double(),
    1.0,
    "rgba(255, 255, 255, 1)",
  )
  set_rect_sprite(
    frame_left,
    1.0,
    (HP_BAR_HEIGHT - 4).to_double(),
    "rgba(255, 255, 255, 1)",
  )
  set_rect_sprite(
    frame_right,
    1.0,
    (HP_BAR_HEIGHT - 4).to_double(),
    "rgba(255, 255, 255, 1)",
  )

  let state = { root, fill_light, fill_dark, percent: 0, ttl_ms: 0.0 }
  upsert_fill_sprite(state)
  state
}

///|
fn refresh_hpbar_state(mob : Mob, state : MobHpBarState) -> Unit {
  let head = mob.get_head_position()
  let body = mob.get_position()
  let offset = (head - body).shift_y(HP_BAR_TOP_SHIFT).to_vec2d()
  @transform2d.set_xy(state.root, offset)
}

///|
/// Push an incoming mob hp update event into the hp bar queue.
pub fn enqueue_hp_event(oid : Int, percent : Int, player_level : Int) -> Unit {
  hp_events.push({ oid, percent, player_level })
}

///|
/// Register local server message handler for mob hp updates.
pub fn setup_mob_hpbar_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "mob_hp",
    @server_proto.Opcode::SHOW_MOB_HP.int_value(),
    fn(json) raise {
      let msg : MobHpMessage = @json.from_json(json)
      enqueue_hp_event(msg.oid, msg.percent, 0)
    },
  )
}

///|
/// ECS system that updates and renders mob hp bars using selene child entities.
pub fn mob_hpbars_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  guard get_map_mobs() is Some(mobs) else {
    while hp_events.pop() is Some(_) {

    }
    for _, state in hp_states {
      if state.root.is_alive() {
        state.root.destroy()
      }
    }
    hp_states.clear()
    return
  }

  for ;; {
    guard hp_events.pop() is Some(event) else { break }
    ignore(event.player_level)
    guard mobs.get_mob(event.oid) is Some(mob) else { continue }
    let state = hp_states.get_or_init(event.oid, fn() {
      create_hpbar_state(mob.get_entity())
    })
    state.percent = event.percent |> @cmp.maximum(0) |> @cmp.minimum(100)
    state.ttl_ms = 2000.0
    refresh_hpbar_state(mob, state)
    upsert_fill_sprite(state)
  }

  let to_remove : Array[Int] = []
  let delta_ms = delta * 1000.0
  for oid, state in hp_states {
    guard mobs.get_mob(oid) is Some(mob) else {
      if state.root.is_alive() {
        state.root.destroy()
      }
      to_remove.push(oid)
      continue
    }
    if !mob.is_alive() {
      if state.root.is_alive() {
        state.root.destroy()
      }
      to_remove.push(oid)
      continue
    }
    state.ttl_ms -= delta_ms
    if state.ttl_ms <= 0.0 || state.percent <= 0 {
      if state.root.is_alive() {
        state.root.destroy()
      }
      to_remove.push(oid)
      continue
    }
    refresh_hpbar_state(mob, state)
  }
  for oid in to_remove {
    hp_states.remove(oid) |> ignore
  }
}
