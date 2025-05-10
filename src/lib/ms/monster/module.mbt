///|
struct Module {
  map_mobs : MapMobs
  mob_combat : MobCombat
}

///|
pub fn Module::new(
  add_task_fn : (@utils.Future[Unit]) -> Unit,
  network : @net.Network
) -> Module {
  let mobs = MapMobs::new()
  { map_mobs: mobs, mob_combat: MobCombat::new(mobs, add_task_fn, network) }
}

///|
pub fn get_map_mobs(self : Module) -> MapMobs {
  self.map_mobs
}

///|
pub fn make_handlers(
  self : Module,
  player_stats_getter : () -> @char_stats.CharStats?
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      @net.SPAWN_MOB,
      @net.with_log(@net.SPAWN_MOB, log_recv=false, fn(recv : @net.InPacket) {
        handle_spawn_mob!(self.map_mobs, recv)
      }),
    ),
    (
      @net.SPAWN_MOB_C,
      @net.with_log(@net.SPAWN_MOB_C, fn(recv : @net.InPacket) {
        handle_spawn_mob_controller!(self.map_mobs, recv)
      }),
    ),
    (
      @net.MOB_MOVED,
      @net.with_log(@net.MOB_MOVED, fn(recv : @net.InPacket) {
        handle_mob_moved!(self.map_mobs, self.mob_combat, recv)
      }),
    ),
    (
      @net.MOB_MOVE_RESPONSE,
      @net.with_log(@net.MOB_MOVE_RESPONSE, log_recv=false, fn(
        recv : @net.InPacket
      ) {
        handle_mob_move_response!(self.mob_combat, recv)
      }),
    ),
    (
      @net.SHOW_MOB_HP,
      @net.with_log(@net.SHOW_MOB_HP, fn(recv : @net.InPacket) {
        handle_show_mob_hp!(self.map_mobs, player_stats_getter, recv)
      }),
    ),
    (
      @net.KILL_MOB,
      @net.with_log(@net.KILL_MOB, fn(recv : @net.InPacket) {
        handle_kill_mob!(self.map_mobs, recv)
      }),
    ),
  ]
  |> Map::from_array
}
