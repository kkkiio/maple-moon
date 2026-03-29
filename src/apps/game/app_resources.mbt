///|
pub(all) struct AppResources {
  char_presentation_resource : @char_look.CharacterPresentationResource
  quest_resource : @quest.QuestResource
  quest_progress : Json
  map_quests_resource : @quest_icon.MapQuestsResource
}

///|
pub async fn AppResources::load() -> AppResources {
  let char_presentation_resource = @char_look.CharacterPresentationResource::load()
  let quest_result = @quest.load_quest_resource()
  let map_quests_resource = @quest_icon.MapQuestsResource::load()
  {
    char_presentation_resource,
    quest_resource: quest_result.0,
    quest_progress: quest_result.1,
    map_quests_resource,
  }
}

///|
pub fn AppResources::install(self : AppResources) -> Unit {
  @char_look.insert_resource(self.char_presentation_resource)
  @quest_log.setup(self.quest_resource)
  @quest_icon.setup(
    self.quest_resource,
    self.quest_progress,
    self.map_quests_resource,
    @npc.request_quest_talk,
  )
}
