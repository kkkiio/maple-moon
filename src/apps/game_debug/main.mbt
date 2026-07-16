///|
fn main {
  let server = @local_server.LocalServer(db=@local_server.BrowserDB())
  let app = @game_app.base_app()
    .add_plugin(@plugins.default_plugin)
    .add_plugin(@console.plugin())
    .add_plugin(@game_app.game_systems(server))
    .add_plugin(@bot_controller.plugin())
  @ecs.set_current_world(app.world())
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  app.run()
}
