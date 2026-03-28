///|
using @server_proto {
  type MobSpawnMessage,
  type MobSpawnControllerMessage,
  type KillMobMessage,
}

///|
pub(all) struct MapMobsContext {
  map_mobs : MapMobs
  physics : @physics.Physics
}

///|
let map_mobs_ctx : Ref[MapMobsContext?] = Ref::new(None)

///|
///|
pub fn set_mobs(ctx : MapMobsContext) -> Unit {
  map_mobs_ctx.val = Some(ctx)
}

///|
pub fn get_map_mobs() -> MapMobs? {
  map_mobs_ctx.val.map(fn(ctx) { ctx.map_mobs })
}

///|
/// Clear all map-scoped monsters and detach monster scene context.
///
/// This is intended to be called on scene/map transitions.
pub fn clear_map_monsters() -> Unit {
  match map_mobs_ctx.val {
    Some({ map_mobs, .. }) => map_mobs.clear()
    None => ()
  }
  map_mobs_ctx.val = None
}

///|
pub fn clear_for_change_map() -> Unit {
  clear_map_monsters()
}

///|
pub fn clear_for_leave_world() -> Unit {
  clear_map_monsters()
}

///|
pub struct MapMobs {
  mobs : Map[Int, Mob]
  loading_mobs : Array[@utils.Future[Result[Mob, Error]]]
  spawns : @queue.Queue[MobSpawn]
  randomizer : @random.Rand
}

///|
pub fn MapMobs::new() -> MapMobs {
  {
    mobs: Map::new(),
    spawns: @queue.new(),
    loading_mobs: Array::new(),
    randomizer: @random.Rand::new(),
  }
}

///|
pub fn MapMobs::spawn(self : MapMobs, spawn : MobSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn MapMobs::add_mob(self : MapMobs, mob : Mob) -> Unit {
  self.mobs.set(mob.get_oid(), mob)
}

///|
pub fn MapMobs::update(self : MapMobs, physics : @physics.Physics) -> Unit {
  for ;; {
    guard self.spawns.pop() is Some(spawn) else { break }
    if not(self.mobs.contains(spawn.oid)) {
      self.loading_mobs.push(
        @io_service.submit_background_task(async fn() {
          spawn.instantiate(self.randomizer)
        }),
      )
    }
  }
  self.loading_mobs.retain(fn(future) {
    guard future.poll() is Some(rs) else { return true }
    match rs {
      Ok(mob) => self.mobs.set(mob.get_oid(), mob)
      Err(e) => @log.error("Failed to load mob", data={ "err": e })
    }
    false
  })
  let to_remove = Array::new()
  for oid, mob in self.mobs {
    let layer = mob.update(physics)
    if layer == -1 {
      to_remove.push(oid)
    }
  }
  for oid in to_remove {
    match self.mobs.get(oid) {
      Some(mob) => {
        mob.destroy()
        self.mobs.remove(oid) |> ignore
      }
      None => ()
    }
  }
}

///|
pub fn MapMobs::set_control(self : MapMobs, oid : Int, control : Bool) -> Unit {
  let mode = if control { 1 } else { 0 }
  match self.mobs.get(oid) {
    Some(mob) => mob.set_control(mode)
    None => ()
  }
}

///|
pub fn MapMobs::clear(self : MapMobs) -> Unit {
  self.loading_mobs.clear()
  while self.spawns.pop() is Some(_) {

  }
  for _, mob in self.mobs {
    mob.destroy()
  }
  self.mobs.clear()
}

///|

///|
pub fn MapMobs::find_colliding(
  self : MapMobs,
  moveobj : @physics.MovingObject,
) -> Int? {
  let horizontal = @struct.Range::new(moveobj.get_last_x(), moveobj.get_x())
  let vertical = @struct.Range::new(moveobj.get_last_y(), moveobj.get_y())
  let player_rect = @struct.Rectangle::from4(
    horizontal.smaller(),
    horizontal.greater(),
    vertical.smaller() - 50,
    vertical.greater(),
  )
  for _, mob in self.mobs {
    match mob.get_live_range() {
      Some(range) =>
        if range.overlaps(player_rect) {
          return Some(mob.get_oid())
        }
      None => ()
    }
  }
  None
}

///|
pub fn MapMobs::create_attack(self : MapMobs, oid : Int) -> @combat.MobAttack? {
  match self.mobs.get(oid) {
    Some(mob) => Some(mob.create_touch_attack())
    None => None
  }
}

///|
pub fn MapMobs::send_movement(
  self : MapMobs,
  oid : Int,
  start : @struct.Point[Int],
  movements : Array[@physics.Movement],
) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.send_movement(start, movements)
    None => ()
  }
}

///|
pub fn MapMobs::get_mob(
  self : MapMobs,
  oid : Int,
  include_dying? : Bool = false,
) -> Mob? {
  guard self.mobs.get(oid) is Some(mob) else { return None }
  if include_dying || mob.is_alive() {
    Some(mob)
  } else {
    None
  }
}

///|
pub fn MapMobs::with_mob(self : MapMobs, oid : Int, f : (Mob) -> Unit) -> Unit {
  match self.get_mob(oid) {
    Some(mob) => f(mob)
    None => ()
  }
}

///|
pub fn MapMobs::for_each_mob(self : MapMobs, f : (Int, Mob) -> Unit) -> Unit {
  for oid, mob in self.mobs {
    f(oid, mob)
  }
}

///|
pub fn MapMobs::remove(self : MapMobs, oid : Int, animation : Int) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.kill(animation)
    None => ()
  }
  if animation == 0 {
    match self.mobs.get(oid) {
      Some(mob) => {
        mob.destroy()
        self.mobs.remove(oid) |> ignore
      }
      None => ()
    }
  }
}

///|
pub fn MapMobs::send_attack(
  self : MapMobs,
  result : @combat.AttackResult,
  attack : @combat.Attack,
  targets : Array[Int],
) -> Unit {
  for target in targets {
    guard self.get_mob(target) is Some(mob) else { continue }
    result.damage_lines[target] = mob.calculate_damage(attack)
    result.mob_count += 1
    if result.mob_count == 1 {
      result.first_oid = target
    }
    result.last_oid = target // last assign wins
  }
}

///|
pub fn MapMobs::contains(
  self : MapMobs,
  oid : Int,
  include_dying? : Bool = false,
) -> Bool {
  self.get_mob(oid, include_dying~) is Some(_)
}

///|
pub fn MapMobs::get_mob_position(
  self : MapMobs,
  oid : Int,
) -> @struct.Point[Int] {
  self
  .get_mob(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_position() })
}

///|
pub fn MapMobs::get_mob_head_position(
  self : MapMobs,
  oid : Int,
) -> @struct.Point[Int] {
  self
  .get_mob(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_head_position() })
}

///|
pub(all) struct MobSpawn {
  oid : Int
  id : Int
  mode : Int
  stance : Int
  fh : Int
  new_spawn : Bool
  team : Int
  position : @struct.Point[Int]
}

///|
pub fn create_mob_spawn(
  oid : Int,
  id : Int,
  mode : Int,
  stance : Int,
  fh : Int,
  new_spawn : Bool,
  team : Int,
  position : @struct.Point[Int],
) -> MobSpawn {
  { oid, id, mode, stance, fh, new_spawn, team, position }
}

///|
pub async fn MobSpawn::instantiate(
  self : MobSpawn,
  randomizer : @random.Rand,
) -> Mob {
  Mob::load(
    self.oid,
    self.id,
    self.mode,
    self.stance,
    self.fh,
    self.new_spawn,
    self.position,
    randomizer,
  )
}

///|
const MOB_ZINDEX_OFFSET = 2000

///|
const MAP_LAYER_STRIDE = 5000

///|
/// Advance map monster simulation once in fixed schedule.
// TODO: Split non-fixed-step logic out of this FixedUpdate system into a separate Update system function.
pub fn map_monsters_fixed_system(_world : @ecs.World) -> Unit {
  guard map_mobs_ctx.val is Some({ map_mobs, physics }) else { return }
  map_mobs.update(physics)
}

///|
/// Sync monster render state in frame update schedule.
pub fn map_monsters_render_system(_world : @ecs.World) -> Unit {
  guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
  for _oid, mob in map_mobs.mobs {
    let entity = mob.entity
    guard mob.animations.get(mob.stance.t) is Some(anim) else { continue }

    // Check for direction/animation change
    if @sprite.sprites().get(entity) is None ||
      mob.last_synced_stance != Some(mob.stance) {
      // Create or Replace sprite
      let flip = mob.stance.face_right && not(mob.no_flip)
      let transform = if flip {
        @selene_math.Transform::from_scale(-1.0, 1.0)
      } else {
        @selene_math.Transform::new()
      }
      let layer = mob.get_layer()
      let z = @graphics.OBJECT_TILE_LAYER_ZINDEX +
        layer * MAP_LAYER_STRIDE +
        MOB_ZINDEX_OFFSET
      let sprite = @ms_animation.sprite_from_animation(
        anim.selene,
        z,
        transform~,
      )
      @sprite.sprites().set(entity, sprite)
      mob.last_synced_stance = Some(mob.stance)
    } else {
      // Only update Z
      let layer = mob.get_layer()
      let z = @graphics.OBJECT_TILE_LAYER_ZINDEX +
        layer * MAP_LAYER_STRIDE +
        MOB_ZINDEX_OFFSET
      if @transform.transforms().get(entity) is Some(current) {
        @transform.transforms().set(entity, {
          ..current,
          translation: @selene_math.Vec3::new(
            current.translation.x,
            current.translation.y,
            z.to_double(),
          ),
        })
      } else {
        @transform.transforms().set(
          entity,
          @transform.Transform::from_xyz(0.0, 0.0, z.to_double()),
        )
      }
    }
  }
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "spawn_mob",
    @server_proto.Opcode::SPAWN_MOB.int_value(),
    fn(json) raise {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : MobSpawnMessage = @json.from_json(json)
      map_mobs.spawn({
        oid: msg.oid,
        id: msg.id,
        mode: 0,
        stance: msg.stance,
        fh: msg.fh,
        new_spawn: true, // Assuming new spawn for map load
        team: msg.team,
        position: @struct.Point::new(msg.x, msg.y),
      })
    },
  )
  @game_server.add_server_message_handler(
    "spawn_mob_controller",
    @server_proto.Opcode::SPAWN_MOB_C.int_value(),
    fn(json) raise {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : MobSpawnControllerMessage = @json.from_json(json)
      map_mobs.spawn({
        oid: msg.oid,
        id: msg.id,
        mode: msg.mode,
        stance: msg.stance,
        fh: msg.fh,
        new_spawn: true,
        team: msg.team,
        position: @struct.Point::new(msg.x, msg.y),
      })
    },
  )
  @game_server.add_server_message_handler(
    "kill_mob",
    @server_proto.Opcode::KILL_MOB.int_value(),
    fn(json) raise {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : KillMobMessage = @json.from_json(json)
      map_mobs.remove(msg.oid, msg.animation)
    },
  )
  setup_mob_hpbar_game_server_handlers()
}
