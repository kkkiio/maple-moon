///|
fn main {
  let server = @local_server.LocalServer(db=@file_db.FileDB())
  let app = @game_app.base_app()
    .add_plugin(@plugins.default_plugin)
    .add_plugin(@game_app.game_systems(server))
  @ecs.set_current_world(app.world())
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  app.run()
}
