///|
using @maple_protocol {
  type MobSpawnMessage,
  type MobSpawnControllerMessage,
  type MobHpMessage,
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
pub fn set_mobs(ctx : MapMobsContext) -> Unit {
  map_mobs_ctx.val = Some(ctx)
}

///|
pub struct MapMobs {
  mobs : @map_object.MapObjects[Mob]
  loading_mobs : Array[@utils.Future[Result[Mob, Error]]]
  spawns : @queue.Queue[MobSpawn]
  randomizer : @utils.Randomizer
}

///|
pub fn MapMobs::new() -> MapMobs {
  {
    mobs: @map_object.MapObjects::new(),
    spawns: @queue.new(),
    loading_mobs: Array::new(),
    randomizer: @utils.Randomizer::new(),
  }
}

///|
pub fn MapMobs::spawn(self : MapMobs, spawn : MobSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn MapMobs::update(self : MapMobs, physics : @physics.Physics) -> Unit {
  for {
    guard self.spawns.pop() is Some(spawn) else { break }
    if not(self.mobs.contains(spawn.oid)) {
      self.loading_mobs.push(
        @io_service.submit_background_task(fn() {
          spawn.instantiate(self.randomizer)
        }),
      )
    }
  }
  self.loading_mobs.retain(fn(future) {
    guard future.poll() is Some(rs) else { return true }
    match rs {
      Ok(mob) => self.mobs.add(mob)
      Err(e) => @log.error({ "err": e }, "Failed to load mob")
    }
    false
  })
  self.mobs.update(physics)
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
pub fn MapMobs::get_mobs(self : MapMobs) -> @map_object.MapObjects[Mob] {
  self.mobs
}

///|
pub fn MapMobs::remove(self : MapMobs, oid : Int, animation : Int) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.kill(animation)
    None => ()
  }
  if animation == 0 {
    self.mobs.remove(oid)
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
    guard self.mobs.get(target) is Some(mob) else { continue }
    result.damage_lines[target] = mob.calculate_damage(attack)
    result.mob_count += 1
    if result.mob_count == 1 {
      result.first_oid = target
    }
    result.last_oid = target // last assign wins
  }
}

///|
pub fn MapMobs::contains(self : MapMobs, oid : Int) -> Bool {
  self.mobs.contains(oid)
}

///|
pub fn MapMobs::get_mob_position(
  self : MapMobs,
  oid : Int,
) -> @struct.Point[Int] {
  self.mobs
  .get(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_position() })
}

///|
pub fn MapMobs::get_mob_head_position(
  self : MapMobs,
  oid : Int,
) -> @struct.Point[Int] {
  self.mobs
  .get(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_head_position() })
}

///|
pub fn MapMobs::send_mobhp(
  self : MapMobs,
  oid : Int,
  percent : Int,
  playerlevel : Int,
) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.show_hp(percent, playerlevel)
    None => ()
  }
}

///|

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
  randomizer : @utils.Randomizer,
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
pub fn map_monsters_system(_delta : Double) -> Unit {
  guard map_mobs_ctx.val is Some({ map_mobs, physics }) else { return }
  let times = @logic_fps.get_logic_times()
  for i = 0; i < times; i = i + 1 {
    map_mobs.update(physics)
  }
  for _oid, mob in map_mobs.mobs.iter2() {
    let entity = mob.entity
    guard mob.animations.get(mob.stance.t) is Some(anim) else { continue }

    // Check for direction/animation change
    if @sprite.sprites.get(entity) is None ||
      mob.last_synced_stance != Some(mob.stance) {
      // Create or Replace sprite
      let flip = mob.stance.face_right && not(mob.no_flip)
      let selene_anim = if flip { anim.selene_r } else { anim.selene_l }
      let layer = mob.get_layer()
      let z = @graphics.OBJECT_TILE_LAYER_ZINDEX +
        layer * MAP_LAYER_STRIDE +
        MOB_ZINDEX_OFFSET
      let sprite = @sprite.Sprite::from_animation(selene_anim, z)
      @sprite.sprites.set(entity, sprite)
      mob.last_synced_stance = Some(mob.stance)
    } else {
      // Only update Z
      match @sprite.sprites.get(entity) {
        Some(sprite) => {
          let layer = mob.get_layer()
          let z = @graphics.OBJECT_TILE_LAYER_ZINDEX +
            layer * MAP_LAYER_STRIDE +
            MOB_ZINDEX_OFFSET
          @sprite.sprites.set(entity, { ..sprite, zindex: z })
        }
        None => ()
      }
    }
  }
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "spawn_mob",
    @net.Opcode::SPAWN_MOB.int_value(),
    fn(json) {
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
    @net.Opcode::SPAWN_MOB_C.int_value(),
    fn(json) {
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
    "mob_hp",
    @net.Opcode::SHOW_MOB_HP.int_value(),
    fn(json) {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : MobHpMessage = @json.from_json(json)
      map_mobs.send_mobhp(msg.oid, msg.percent, 0) // TODO: player level
    },
  )
  @game_server.add_server_message_handler(
    "kill_mob",
    @net.Opcode::KILL_MOB.int_value(),
    fn(json) {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : KillMobMessage = @json.from_json(json)
      map_mobs.remove(msg.oid, msg.animation)
    },
  )
}
