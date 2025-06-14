///|
struct MapMobs {
  mobs : @map_object.MapObjects[Mob]
  loading_mobs : Array[@utils.Future[Result[Mob, Error]]]
  spawns : @queue.T[MobSpawn]
  randomizer : @utils.Randomizer
  string_loader : @resource.SyncLoader
  io_service : @io_task.IOService
}

///|
pub fn MapMobs::new(
  string_loader~ : @resource.SyncLoader,
  io_service : @io_task.IOService
) -> MapMobs {
  {
    mobs: @map_object.MapObjects::new(),
    spawns: @queue.new(),
    loading_mobs: Array::new(),
    randomizer: @utils.Randomizer::default(),
    string_loader,
    io_service,
  }
}

///|
pub fn spawn(self : MapMobs, spawn : MobSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn update(
  self : MapMobs,
  physics : @physics.Physics,
  network : @net.Network
) -> Unit {
  loop self.spawns.pop() {
    Some(spawn) => {
      match self.mobs.get(spawn.oid) {
        Some(mob) => {
          let mode = spawn.mode
          if mode > 0 {
            mob.set_control(mode)
          }
          mob.makeactive()
        }
        None =>
          self.loading_mobs.push(
            self.io_service.submit(fn() {
              spawn.instantiate(self.randomizer, network, self.string_loader)
            }),
          )
      }
      continue self.spawns.pop()
    }
    None => break
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
pub fn set_control(self : MapMobs, oid : Int, control : Bool) -> Unit {
  let mode = if control { 1 } else { 0 }
  match self.mobs.get(oid) {
    Some(mob) => mob.set_control(mode)
    None => ()
  }
}

///|
pub fn clear(self : MapMobs) -> Unit {
  self.mobs.clear()
}

///|
pub fn draw(
  self : MapMobs,
  layer : @map_layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.mobs.draw(layer, viewx, viewy, alpha)
}

///|
pub fn find_colliding(self : MapMobs, moveobj : @physics.MovingObject) -> Int? {
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
pub fn create_attack(self : MapMobs, oid : Int) -> @combat.MobAttack? {
  match self.mobs.get(oid) {
    Some(mob) => Some(mob.create_touch_attack())
    None => None
  }
}

///|
pub fn send_movement(
  self : MapMobs,
  oid : Int,
  start : @struct.Point[Int],
  movements : Array[@physics.Movement]
) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.send_movement(start, movements)
    None => ()
  }
}

///|
pub fn get_mobs(self : MapMobs) -> @map_object.MapObjects[Mob] {
  self.mobs
}

///|
pub fn remove(self : MapMobs, oid : Int, animation : Int) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.kill(animation)
    None => ()
  }
  if animation == 0 {
    self.mobs.remove(oid)
  }
}

///|
pub fn send_attack(
  self : MapMobs,
  result : @combat.AttackResult,
  attack : @combat.Attack,
  targets : Array[Int],
  mobcount : Int,
  network : @net.Network
) -> Unit {
  for target in targets {
    guard self.mobs.get(target) is Some(mob) else { continue }
    result.damage_lines[target] = mob.calculate_damage(attack, network)
    result.mob_count += 1
    if result.mob_count == 1 {
      result.first_oid = target
    }
    if result.mob_count == mobcount {
      result.last_oid = target
    }
  }
}

///|
pub fn contains(self : MapMobs, oid : Int) -> Bool {
  self.mobs.contains(oid)
}

///|
pub fn get_mob_position(self : MapMobs, oid : Int) -> @struct.Point[Int] {
  self.mobs
  .get(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_position() })
}

///|
pub fn get_mob_head_position(self : MapMobs, oid : Int) -> @struct.Point[Int] {
  self.mobs
  .get(oid)
  .map_or(@struct.Point::new(0, 0), fn(mob) { mob.get_head_position() })
}

///|
pub fn send_mobhp(
  self : MapMobs,
  oid : Int,
  percent : Int,
  playerlevel : Int
) -> Unit {
  match self.mobs.get(oid) {
    Some(mob) => mob.show_hp(percent, playerlevel)
    None => ()
  }
}

///|
struct MobSpawn {
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
pub async fn instantiate(
  self : MobSpawn,
  randomizer : @utils.Randomizer,
  network : @net.Network,
  string_loader : @resource.SyncLoader
) -> Mob raise {
  Mob::load(
    self.oid,
    self.id,
    self.mode,
    self.stance,
    self.fh,
    self.new_spawn,
    self.team,
    self.position,
    randomizer,
    network,
    string_loader,
  )
}

///|
let mob_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("mob")
