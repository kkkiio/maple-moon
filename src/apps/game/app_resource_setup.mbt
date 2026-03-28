///|
/// App 级别的资源初始化系统
/// 在 GameSetup 阶段异步加载静态资源，完成后切换到 SelectCharacter
let loading_ref : Ref[@utils.Future[Result[Unit, Error]]?] = Ref::new(None)

///|
pub fn app_resource_setup_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is @game_state.GamePhase::GameSetup else {
    return
  }
  guard loading_ref.val is Some(loading) else {
    loading_ref.val = Some(
      @io_service.submit_background_task(async fn() {
        let quest_result = @quest.load_quest_resource()
        let map_quests_resource = @quest_icon.MapQuestsResource::load()
        @quest_log.setup(quest_result.0)
        @quest_icon.setup(
          quest_result.0,
          quest_result.1,
          map_quests_resource,
          @npc.request_quest_talk,
        )
      }),
    )
    return
  }
  guard loading.poll() is Some(result) else { return }
  loading_ref.val = None
  match result {
    Ok(_) => @game_state.set_next_phase(@game_state.GamePhase::SelectCharacter)
    Err(e) =>
      @log.fatal("app resource setup failed", data={ "error": e.to_string() })
  }
}
