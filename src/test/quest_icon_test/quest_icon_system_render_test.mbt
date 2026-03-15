///|
fn parse_json_file_local(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
fn setup_ui_window2_loader_local() -> Unit {
  @resource.set_ui_window_2_loader(
    @resource.AsyncLoader::new(
      "test_local_ui_window_2",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new(
        "assets/ui/UIWindow2.img",
      ),
    ),
  )
}

///|
async fn load_quest_icon_animations() -> (
  @resource.NxAnimation,
  @resource.NxAnimation,
  @resource.NxAnimation,
) {
  setup_ui_window2_loader_local()
  let loader = @resource.get_ui_window_2_loader()
  let available_json = loader.load_resource(["QuestIcon", "0"]) catch {
    _ => panic()
  }
  let in_progress_json = loader.load_resource(["QuestIcon", "1"]) catch {
    _ => panic()
  }
  let completed_json = loader.load_resource(["QuestIcon", "2"]) catch {
    _ => panic()
  }
  (
    @json.from_json(available_json) catch {
      _ => panic()
    },
    @json.from_json(in_progress_json) catch {
      _ => panic()
    },
    @json.from_json(completed_json) catch {
      _ => panic()
    },
  )
}

///|
fn setup_quest_icon_app() -> Unit {
  @capture_app.init_app(
    @system.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@quest_icon.quest_icon_system, system_name="quest_icon_system"),
  )
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
}

///|
fn run_frames_local(times : Int) -> Unit {
  for _ in 0..<times {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "quest_icon_system renders snapshot and handles click dispatch" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  defer @quest_icon.clear_context()

  setup_quest_icon_app()
  let (available, in_progress, completed) = load_quest_icon_animations()
  @quest_icon.set_resources_for_test(available, in_progress, completed)

  let build_called = Ref::new(false)
  @quest_icon.set_context(
    fn(npc_id) {
      if npc_id == 1012000 {
        Some({ npc_id, quest_id: 1000, state: @quest.QuestIconState::AVAILABLE })
      } else {
        None
      }
    },
    fn(quest_id, npc_id) {
      build_called.val = quest_id == 1000 && npc_id == 1012000
      Some({
        npc_id,
        speaker: @npc.Speaker::NPC_LEFT,
        str: "quest icon click",
        talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
      })
    },
  )

  let npc_entity = @entity.Entity::new()
  let npc_object = @physics.MovingObject::new(on_pos_change=fn(pos) {
    @position.positions.set(npc_entity, @position.Position(pos))
  })
  npc_object.set_position(@selene_math.Vec2D(240.0, 200.0))
  @quest_icon.upsert_npc(1, 1012000, npc_entity, npc_object)

  run_frames_local(8)
  @capture_app.snapshot(
    "src/test/quest_icon_test/__snapshot__/quest_icon_system_default.png",
  )
  inspect(npc_entity.get_children().length() > 0, content="true")

  @inputs.mouse.pos = @selene_math.Vec2D(240.0, 104.0)
  @inputs.just_pressed_mouse.left_button = true
  @quest_icon.quest_icon_system(0.016)
  @inputs.just_pressed_mouse.left_button = false
  inspect(build_called.val, content="true")
}
