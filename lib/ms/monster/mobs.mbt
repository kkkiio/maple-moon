struct MapMobs {
  mobs : @map_object.MapObjects[Mob]
  spawns : @queue.T[MobSpawn]
}

pub fn MapMobs::new() -> MapMobs {
  { mobs: @map_object.MapObjects::new(), spawns: @queue.T::new() }
}

pub fn spawn(self : MapMobs, spawn : MobSpawn) -> Unit {
  self.spawns.push(spawn)
}

pub fn update(self : MapMobs, physics : @physics.Physics) -> Unit! {
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
        None => self.mobs.add(spawn.instantiate!())
      }
      continue self.spawns.pop()
    }
    None => break
  }
  self.mobs.update(physics)
}

pub fn set_control(self : MapMobs, oid : Int, control : Bool) -> Unit {
  let mode = if control { 1 } else { 0 }
  match self.mobs.get(oid) {
    Some(mob) => mob.set_control(mode)
    None => ()
  }
}

pub fn clear(self : MapMobs) -> Unit {
  self.mobs.clear()
}

pub fn draw(
  self : MapMobs,
  layer : @layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.mobs.draw(layer, viewx, viewy, alpha)
}

pub fn find_colliding(self : MapMobs, moveobj : @physics.MovingObject) -> Int? {
  let horizontal = @struct.Range::new(moveobj.get_last_x(), moveobj.get_x())
  let vertical = @struct.Range::new(moveobj.get_last_y(), moveobj.get_y())
  let player_rect = @struct.Rectangle::from4(
    horizontal.smaller(),
    horizontal.greater(),
    vertical.smaller() - 50,
    vertical.greater(),
  )
  for _, mob in self.mobs.iter2() {
    if mob.is_alive() && mob.is_in_range(player_rect) {
      return Some(mob.get_oid())
    }
  }
  None
}

pub fn create_attack(self : MapMobs, oid : Int) -> @combat.MobAttack? {
  match self.mobs.get(oid) {
    Some(mob) => Some(mob.create_touch_attack())
    None => None
  }
}

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

pub fn get_mobs(self : MapMobs) -> @map_object.MapObjects[Mob] {
  self.mobs
}

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

pub fn instantiate(self : MobSpawn) -> Mob! {
  Mob::new!(
    self.oid,
    self.id,
    self.mode,
    self.stance,
    self.fh,
    self.new_spawn,
    self.team,
    self.position,
  )
}

fn mob_loader() -> @resource.Loader {
  @resource.Loader::new("mob")
}
