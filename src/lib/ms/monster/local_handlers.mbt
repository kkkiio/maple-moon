///|

///|
priv struct MobSpawnJSON {
  oid : Int
  id : Int
  x : Int
  y : Int
  stance : Int
  fh : Int
  team : Int
} derive(FromJson)

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "spawn_mob",
    @net.Opcode::SPAWN_MOB.int_value(),
    fn(json) {
      guard map_mobs_ctx.val is Some({ map_mobs, .. }) else { return }
      let msg : MobSpawnJSON = @json.from_json(json)
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
}
