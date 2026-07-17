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
let map_mobs_ctx : Ref[MapMobsContext?] = Ref(None)

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
  spawns : @queue.Queue[MobSpawn]
  randomizer : @random.Rand
}

///|
pub fn MapMobs::MapMobs() -> MapMobs {
  { mobs: Map([]), spawns: @queue.Queue([]), randomizer: @random.Rand::new() }
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
/// Drain queued monster spawns and advance loaded monsters.
///
/// # Example
/// ```moonbit nocheck
/// map_mobs.update(physics)
/// ```
///
/// # Panics
/// Panics after logging when any queued monster's required resource closure
/// cannot be loaded.
pub fn MapMobs::update(self : MapMobs, physics : @physics.Physics) -> Unit {
  for ;; {
    guard self.spawns.pop() is Some(spawn) else { break }
    if self.mobs.contains(spawn.oid) {
      continue
    }
    let mob = spawn.instantiate(self.randomizer) catch {
      error => {
        @log.error("failed to load required mob resources", data={
          "oid": spawn.oid,
          "mob_id": spawn.id,
          "error": error,
        })
        abort(
          "mob resource load failed: oid=\{spawn.oid}, mob_id=\{spawn.id}, error=\{error}",
        )
      }
    }
    self.mobs[spawn.oid] = mob
  }
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
  let horizontal = Range(moveobj.get_last_x(), moveobj.get_x())
  let vertical = Range(moveobj.get_last_y(), moveobj.get_y())
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
  self.get_mob(oid).map_or(Point(0, 0), fn(mob) { mob.get_position() })
}

///|
pub fn MapMobs::get_mob_head_position(
  self : MapMobs,
  oid : Int,
) -> @struct.Point[Int] {
  self.get_mob(oid).map_or(Point(0, 0), fn(mob) { mob.get_head_position() })
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
/// Instantiate a queued monster spawn from its required resource closure.
///
/// # Example
/// ```moonbit nocheck
/// let mob = try! spawn.instantiate(@random.Rand::new())
/// ignore(mob)
/// ```
///
/// # Errors
/// Raises when the monster resource or any referenced animation cannot be
/// loaded.
pub fn MobSpawn::instantiate(
  self : MobSpawn,
  randomizer : @random.Rand,
) -> Mob raise {
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

    let sprite_missing = @sprite.sprites().get(entity) is None
    let animation_changed = sprite_missing ||
      (match mob.last_synced_stance {
        Some(previous) => previous.t != mob.stance.t
        None => true
      })
    if sprite_missing || mob.last_synced_stance != Some(mob.stance) {
      let flip = mob.stance.face_right && !mob.no_flip
      let layer = mob.get_layer()
      let y = mob.get_position().y
      let z = @graphics.map_mob_z(layer, y)
      @sprite.sprites().set(entity, anim.clip.sprite(flip_x=flip))
      if animation_changed {
        @selene_animation.animation_target_ids().set(
          entity,
          @selene_animation.AnimationTargetId("self"),
        )
        @selene_animation.animated_bys().set(
          entity,
          @selene_animation.AnimatedBy(entity),
        )
        @selene_animation.animation_graph_handles().set(
          entity,
          mob.animation_graph,
        )
        let player = @selene_animation.animation_players().get_or_init(entity, fn() {
          @selene_animation.AnimationPlayer()
        })
        let transitions = @selene_animation.animation_transitions().get_or_init(
          entity,
          fn() { @selene_animation.AnimationTransitions() },
        )
        let repeat = if anim.meta.loop_ {
          @selene_animation.RepeatAnimation::Forever
        } else {
          @selene_animation.RepeatAnimation::Never
        }
        ignore(transitions.play(player, anim.node, 0.0, repeat~))
      }
      let pos = mob.get_position()
      @transform.transforms().set(
        entity,
        @transform.Transform::from_xyz(
          pos.x.to_double(),
          pos.y.to_double(),
          z.to_double(),
        ),
      )
      mob.last_synced_stance = Some(mob.stance)
    } else {
      // Only update Z
      let layer = mob.get_layer()
      let y = mob.get_position().y
      let z = @graphics.map_mob_z(layer, y)
      if @transform.transforms().get(entity) is Some(current) {
        @transform.transforms().set(entity, {
          ..current,
          translation: @selene_math.Vec3(
            current.translation.x,
            current.translation.y,
            z.to_double(),
          ),
        })
      } else {
        let pos = mob.get_position()
        @transform.transforms().set(
          entity,
          @transform.Transform::from_xyz(
            pos.x.to_double(),
            pos.y.to_double(),
            z.to_double(),
          ),
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
        position: Point(msg.x, msg.y),
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
        position: Point(msg.x, msg.y),
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
