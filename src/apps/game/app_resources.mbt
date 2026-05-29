///|
pub(all) struct AppResources {
  basic_item_resource : @item.BasicItemResource
  char_presentation_resource : @char_look.CharacterPresentationResource
  quest_resource : @quest.QuestResource
  quest_progress : Json
  map_quests_resource : @quest_icon.MapQuestsResource
  cursor_animation_data : @cursor.CursorAnimationData
}

///|
/// Load all app-wide resources before entering the first interactive scene.
///
/// # Example
/// ```moonbit nocheck
/// let resources = try! AppResources::load()
/// resources.install()
/// ```
pub fn AppResources::load() -> AppResources raise {
  let basic_item_resource = @item.BasicItemResource::load()
  let char_presentation_resource = @char_look.CharacterPresentationResource::load()
  let quest_result = @quest.load_quest_resource()
  let map_quests_resource = @quest_icon.MapQuestsResource::load()
  let cursor_animation_data = @cursor.CursorAnimationData::load(
    "assets/UI/Basic.img/Cursor/cursor_animation.json",
  )
  {
    basic_item_resource,
    char_presentation_resource,
    quest_resource: quest_result.0,
    quest_progress: quest_result.1,
    map_quests_resource,
    cursor_animation_data,
  }
}

///|
pub fn AppResources::install(self : AppResources) -> Unit {
  self.basic_item_resource.install()
  @item.insert_resource(self.basic_item_resource)
  @char_look.insert_resource(self.char_presentation_resource)
  @quest_log.setup(self.quest_resource)
  @quest_icon.setup(
    self.quest_resource,
    self.quest_progress,
    self.map_quests_resource,
    @npc.request_quest_talk,
  )
  @cursor.init_cursor(@cursor.Cursor::new(self.cursor_animation_data))
}
