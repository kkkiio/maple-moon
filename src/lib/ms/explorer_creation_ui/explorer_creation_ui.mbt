///|
using @server_proto {
  type CreateCharacterMessage,
  type CreateCharacterResultMessage,
}

///|
const JOB_ID_EXPLORER = 1

///|
priv struct PreviewState {
  mut loading : @utils.Future[
    Result[(@char_look.CharLook, ExplorerLookConfig), Error],
  ]?
  mut loaded : (@char_look.CharLook, ExplorerLookConfig)?
}

///|

///|
priv struct ExplorerCreationUI {
  resource : ExplorerCreationUIResource
  char_presentation_resource : @char_look.CharacterPresentationResource
  model : ExplorerCreationModel
  randomizer : @random.Rand
  preview : PreviewState
  entities : Array[@entity.Entity]
  click_bindings : Array[(@entity.Entity, UiAction)]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  mut dirty : Bool
  mut cloud_x : Double
  mut debug_click_event_total : Int
  mut debug_action_total : Int
  mut debug_last_action : String?
}

///|
priv enum UiAction {
  ChooseMale
  ChooseFemale
  CancelToSelect
  PrevPart(String)
  NextPart(String)
  CustomizeConfirm
  ConfirmSubmit
  ConfirmBack
}

///|
let creation_ui_ref : Ref[ExplorerCreationUI?] = Ref::new(None)

///|
let creation_ui_loading_future : Ref[
  @utils.Future[
    Result[
      (ExplorerCreationUIResource, @char_look.CharacterPresentationResource),
      Error,
    ],
  ]?,
] = Ref::new(None)

///|
let opening_char_presentation_resource_ref : Ref[
  @char_look.CharacterPresentationResource?,
] = Ref::new(None)

///|
/// Open explorer creation UI.
pub fn open_explorer_creation_ui(
  resource : @char_look.CharacterPresentationResource,
) -> Unit {
  close_explorer_creation_ui()
  opening_char_presentation_resource_ref.val = Some(resource)
}

///|
/// Close explorer creation UI and clear pending tasks.
pub fn close_explorer_creation_ui() -> Unit {
  creation_ui_loading_future.val = None
  opening_char_presentation_resource_ref.val = None
  match creation_ui_ref.val {
    Some(ui) => {
      ui.destroy()
      creation_ui_ref.val = None
    }
    None => ()
  }
}

///|
/// Returns whether explorer creation UI scene is currently mounted.
pub fn is_explorer_creation_ui_open() -> Bool {
  @game_state.current_phase()
  is @game_state.GamePhase::ExplorerCharacterCreation &&
  creation_ui_ref.val is Some(_)
}

///|
fn init {
  @console.register_state_section("explorer_creation", fn() {
    let (stage, error, click_event_total, action_total, last_action) = match
      creation_ui_ref.val {
      Some(ui) =>
        (
          Some(stage_to_string(ui.model.stage)),
          ui.model.error_message,
          ui.debug_click_event_total,
          ui.debug_action_total,
          ui.debug_last_action,
        )
      None => (None, None, 0, 0, None)
    }
    let mouse = @inputs.mouse.pos
    {
      "open": is_explorer_creation_ui_open(),
      "stage": stage,
      "error": error,
      "mouse": [mouse[@selene_math.X], mouse[@selene_math.Y]],
      "click_event_total": click_event_total,
      "action_total": action_total,
      "last_action": last_action,
    }
  })
}

///|
fn stage_to_string(stage : UiStage) -> String {
  match stage {
    UiStage::ChoosingGender => "ChoosingGender"
    UiStage::CustomizingLook => "CustomizingLook"
    UiStage::ConfirmingName => "ConfirmingName"
    UiStage::Submitting => "Submitting"
  }
}

///|
extern "js" fn now_millis() -> Int =
  #| () => Math.trunc(Date.now())

///|
fn action_to_string(action : UiAction) -> String {
  match action {
    UiAction::ChooseMale => "ChooseMale"
    UiAction::ChooseFemale => "ChooseFemale"
    UiAction::CancelToSelect => "CancelToSelect"
    UiAction::PrevPart(part) => "PrevPart(\{part})"
    UiAction::NextPart(part) => "NextPart(\{part})"
    UiAction::CustomizeConfirm => "CustomizeConfirm"
    UiAction::ConfirmSubmit => "ConfirmSubmit"
    UiAction::ConfirmBack => "ConfirmBack"
  }
}

///|
fn new_random_name(randomizer : @random.Rand) -> String {
  ignore(randomizer)
  "explorer" + now_millis().to_string()
}

///|
fn new_ui(
  resource : ExplorerCreationUIResource,
  char_presentation_resource : @char_look.CharacterPresentationResource,
) -> ExplorerCreationUI {
  let randomizer = @random.Rand::new()
  {
    resource,
    char_presentation_resource,
    model: new_model(randomizer, resource),
    randomizer,
    preview: { loading: None, loaded: None },
    entities: [],
    click_bindings: [],
    click_reader: @event.EventReader::new(),
    dirty: true,
    cloud_x: 200.0,
    debug_click_event_total: 0,
    debug_action_total: 0,
    debug_last_action: None,
  }
}

///|
fn ExplorerCreationUI::spawn_entity(
  self : ExplorerCreationUI,
  sprite : @sprite.Sprite,
  x : Int,
  y : Int,
) -> Unit {
  let entity = @entity.Entity::new()
  self.entities.push(entity)
  @sprite.sprites().set(entity, sprite)
  @transform2d.set_xy(entity, @selene_math.Vec2(x.to_double(), y.to_double()))
}

///|
fn ExplorerCreationUI::spawn_text(
  self : ExplorerCreationUI,
  text : String,
  x : Int,
  y : Int,
  z : Int,
  align? : @selene_math.HAlign = @selene_math.Left,
) -> Unit {
  let entity = @entity.Entity::new()
  self.entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(220.0, 20.0),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  @selene_ui.texts().set(entity, @selene_ui.Text::new(text))
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::from_css("12px Menlo"),
  )
  @selene_ui.text_colors().set(entity, @selene_ui.TextColor::from_css("black"))
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout::new(align~, baseline=@selene_math.Top),
  )
}

///|
fn ExplorerCreationUI::spawn_click_button(
  self : ExplorerCreationUI,
  res : @ui.MapleButtonResource,
  x : Int,
  y : Int,
  action : UiAction,
  debug_name : String,
) -> Unit {
  let button_entity = @entity.Entity::new()
  self.entities.push(button_entity)
  @transform2d.set_xy(
    button_entity,
    @selene_math.Vec2(x.to_double(), y.to_double()),
  )
  @sprite.sprites().set(
    button_entity,
    @ms_animation.sprite_from_animation(
      res.selene_animations[@ui.ButtonState::NORMAL],
      10,
    ),
  )

  let click_entity = @entity.Entity::new()
  self.entities.push(click_entity)
  @selene_ui.nodes().set(
    click_entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(x.to_double(), y.to_double()),
      size=@selene_math.Vec2(
        res.dimensions.x.to_double(),
        res.dimensions.y.to_double(),
      ),
    ),
  )
  @selene_ui.z_indexes().set(click_entity, @selene_ui.ZIndex::new(3000))
  @selene_ui.buttons().set(click_entity, @selene_ui.Button::new())
  self.click_bindings.push((click_entity, action))
  @console.register_ui_entity("explorer_creation", debug_name, click_entity)
}

///|
fn ExplorerCreationUI::clear_scene(self : ExplorerCreationUI) -> Unit {
  self.click_bindings.clear()
  for entity in self.entities {
    @console.unregister_ui_entity(entity)
    entity.destroy()
  }
  self.entities.clear()
}

///|
fn ExplorerCreationUI::destroy_loaded_preview(
  self : ExplorerCreationUI,
) -> Unit {
  match self.preview.loaded {
    Some((look, _)) => look.get_root_entity().destroy()
    None => ()
  }
  self.preview.loaded = None
}

///|
fn ExplorerCreationUI::destroy(self : ExplorerCreationUI) -> Unit {
  self.clear_scene()
  self.destroy_loaded_preview()
}

///|
fn return_to_select_character() -> Unit {
  close_explorer_creation_ui()
  @game_state.set_next_phase(@game_state.GamePhase::SelectCharacter)
}

///|
fn ExplorerCreationUI::request_preview_if_needed(
  self : ExplorerCreationUI,
) -> Unit {
  if self.model.stage == UiStage::Submitting {
    return
  }
  match self.preview.loaded {
    Some((_, loaded_config)) => if loaded_config == self.model.config { return }
    None => ()
  }
  match self.preview.loading {
    Some(_) => ()
    None => {
      let config = self.model.config
      let resource = self.char_presentation_resource
      let draw_info = resource.draw_info
      self.preview.loading = Some(
        @io_service.submit_background_task(async fn() {
          let body = resource.load_body_by_skin_id(
            config_to_look_entry(config, self.resource).skin,
          )
          let hair = resource.load_hair_by_id(
            config_to_look_entry(config, self.resource).hairid,
          )
          let face = resource.load_face_by_id(
            config_to_look_entry(config, self.resource).faceid,
          )
          let entity = @entity.Entity::new()
          let look = @char_look.CharLook::load(
            entity,
            config_to_look_entry(config, self.resource),
            body,
            hair,
            face,
            draw_info,
          )
          (look, config)
        }),
      )
    }
  }
}

///|
fn ExplorerCreationUI::poll_preview(self : ExplorerCreationUI) -> Unit {
  guard self.preview.loading is Some(fut) else { return }
  guard fut.poll() is Some(res) else { return }
  self.preview.loading = None
  match res {
    Ok((look, config)) =>
      if config == self.model.config {
        self.destroy_loaded_preview()
        look.set_pos(@selene_math.Vec2(394.0, 339.0))
        look.set_stance(@char_stance.StanceId::STAND1)
        look.set_facing_right(true)
        look.play_animations()
        self.preview.loaded = Some((look, config))
        self.dirty = true
      } else {
        look.get_root_entity().destroy()
      }
    Err(err) => {
      self.model.error_message = Some(err.to_string())
      self.dirty = true
    }
  }
}

///|
fn ExplorerCreationUI::make_submit_packet(
  self : ExplorerCreationUI,
) -> CreateCharacterMessage {
  let choices = choices_for_config(self.model.config, self.resource)
  {
    name: self.model.generated_name,
    job: JOB_ID_EXPLORER,
    face: choices.faces[self.model.config.face_idx],
    hair: choices.hairs[self.model.config.hair_idx],
    hairc: choices.haircolors[self.model.config.hair_color_idx],
    skin: choices.skins[self.model.config.skin_idx],
    top: choices.tops[self.model.config.top_idx],
    bot: choices.bots[self.model.config.bot_idx],
    shoes: choices.shoes[self.model.config.shoe_idx],
    weapon: choices.weapons[self.model.config.weapon_idx],
    female: self.model.config.female,
  }
}

///|
fn ExplorerCreationUI::build_common_scene(self : ExplorerCreationUI) -> Unit {
  self.spawn_entity(
    @ms_animation.sprite_from_picture(self.resource.sky, 0),
    0,
    -100,
  )
  self.spawn_entity(
    @ms_animation.sprite_from_picture(self.resource.cloud, 1),
    self.cloud_x.to_int(),
    310,
  )
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.back14, 2),
    250,
    302,
  )
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.signboard2, 3),
    234,
    235,
  )
  if self.preview.loaded is Some((_, _)) {
    ()
  }
}

///|
fn ExplorerCreationUI::build_gender_scene(self : ExplorerCreationUI) -> Unit {
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.board_gender_top, 5),
    486,
    95,
  )
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.board_gender_mid, 5),
    486,
    209,
  )
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.board_gender_bottom, 5),
    486,
    329,
  )
  self.spawn_text("Choose your gender", 580, 162, 9, align=@selene_math.Center)
  self.spawn_click_button(
    self.resource.bt_gender_male,
    487,
    109,
    UiAction::ChooseMale,
    "gender_male",
  )
  self.spawn_click_button(
    self.resource.bt_gender_female,
    567,
    109,
    UiAction::ChooseFemale,
    "gender_female",
  )
  self.spawn_click_button(
    self.resource.bt_no,
    640,
    394,
    UiAction::CancelToSelect,
    "gender_cancel",
  )
}

///|
fn ExplorerCreationUI::build_customize_scene(self : ExplorerCreationUI) -> Unit {
  self.spawn_entity(
    @ms_animation.sprite_from_animation(self.resource.board_char_set, 5),
    486,
    95,
  )
  for i, anim in self.resource.avatar_sel {
    let offset_index = if i >= 2 { i + 1 } else { i }
    self.spawn_entity(
      @ms_animation.sprite_from_animation(anim, 6),
      497,
      197 + offset_index * 18,
    )
  }
  let rows = config_label_rows(self.model.config, self.resource)
  let parts = [
    "face", "hair", "hair_color", "skin", "top", "bottom", "shoes", "weapon",
  ]
  for i, row in rows {
    let (label, value) = row
    let part = parts[i]
    self.spawn_text(
      "\{label}: \{value}",
      625,
      193 + i * 18,
      9,
      align=@selene_math.Center,
    )
    self.spawn_click_button(
      self.resource.bt_left,
      552,
      198 + i * 18,
      UiAction::PrevPart(part),
      "customize_prev_\{part}",
    )
    self.spawn_click_button(
      self.resource.bt_right,
      684,
      198 + i * 18,
      UiAction::NextPart(part),
      "customize_next_\{part}",
    )
  }
  self.spawn_click_button(
    self.resource.bt_yes,
    514,
    394,
    UiAction::CustomizeConfirm,
    "customize_yes",
  )
  self.spawn_click_button(
    self.resource.bt_no,
    640,
    394,
    UiAction::CancelToSelect,
    "customize_cancel",
  )
}

///|
fn ExplorerCreationUI::build_confirm_scene(self : ExplorerCreationUI) -> Unit {
  self.spawn_entity(
    @ms_animation.sprite_from_picture(self.resource.nameboard, 5),
    486,
    95,
  )
  self.spawn_text("Name", 528, 185, 9)
  self.spawn_text(
    self.model.generated_name,
    625,
    185,
    9,
    align=@selene_math.Center,
  )
  self.spawn_text(
    "Create this explorer?",
    625,
    240,
    9,
    align=@selene_math.Center,
  )
  self.spawn_click_button(
    self.resource.bt_yes,
    514,
    394,
    UiAction::ConfirmSubmit,
    "confirm_yes",
  )
  self.spawn_click_button(
    self.resource.bt_no,
    640,
    394,
    UiAction::ConfirmBack,
    "confirm_no",
  )
}

///|
fn ExplorerCreationUI::build_submitting_scene(
  self : ExplorerCreationUI,
) -> Unit {
  self.spawn_entity(
    @ms_animation.sprite_from_picture(self.resource.nameboard, 5),
    486,
    95,
  )
  self.spawn_text(
    "Creating explorer...",
    625,
    210,
    9,
    align=@selene_math.Center,
  )
}

///|
fn ExplorerCreationUI::rebuild_scene(self : ExplorerCreationUI) -> Unit {
  self.clear_scene()
  self.build_common_scene()
  match self.model.stage {
    UiStage::ChoosingGender => self.build_gender_scene()
    UiStage::CustomizingLook => self.build_customize_scene()
    UiStage::ConfirmingName => self.build_confirm_scene()
    UiStage::Submitting => self.build_submitting_scene()
  }
  match self.model.error_message {
    Some(message) =>
      self.spawn_text(message, 625, 432, 9, align=@selene_math.Center)
    None => ()
  }
  self.dirty = false
}

///|
fn ExplorerCreationUI::update(self : ExplorerCreationUI) -> Unit {
  self.cloud_x += 0.5
  let click_events = @selene_ui.click_event_bus.read(self.click_reader)
  for event in click_events {
    guard event.button is @inputs.MouseButton::Left else { continue }
    self.debug_click_event_total = self.debug_click_event_total + 1
    for binding in self.click_bindings {
      let (entity, action) = binding
      if entity == event.entity {
        self.apply_action(action)
        break
      }
    }
  }
  self.request_preview_if_needed()
  self.poll_preview()
  if self.dirty {
    self.rebuild_scene()
  }
}

///|
fn ExplorerCreationUI::apply_action(
  self : ExplorerCreationUI,
  action : UiAction,
) -> Unit {
  self.debug_action_total = self.debug_action_total + 1
  self.debug_last_action = Some(action_to_string(action))
  match action {
    UiAction::ChooseMale => {
      self.model.config.female = false
      self.model.config.skin_idx = 0
      self.model.config.hair_color_idx = 0
      self.model.config.face_idx = 0
      self.model.config.hair_idx = 0
      self.model.config.top_idx = 0
      self.model.config.bot_idx = 0
      self.model.config.shoe_idx = 0
      self.model.config.weapon_idx = 0
      self.model.stage = UiStage::CustomizingLook
      self.model.error_message = None
      self.dirty = true
    }
    UiAction::ChooseFemale => {
      self.model.config.female = true
      self.model.config.skin_idx = 0
      self.model.config.hair_color_idx = 0
      self.model.config.face_idx = 0
      self.model.config.hair_idx = 0
      self.model.config.top_idx = 0
      self.model.config.bot_idx = 0
      self.model.config.shoe_idx = 0
      self.model.config.weapon_idx = 0
      self.model.stage = UiStage::CustomizingLook
      self.model.error_message = None
      self.dirty = true
    }
    UiAction::CancelToSelect => return_to_select_character()
    UiAction::PrevPart(part) => {
      update_config_index(self.model, self.resource, part, -1)
      self.model.error_message = None
      self.dirty = true
    }
    UiAction::NextPart(part) => {
      update_config_index(self.model, self.resource, part, 1)
      self.model.error_message = None
      self.dirty = true
    }
    UiAction::CustomizeConfirm => {
      self.model.generated_name = new_random_name(self.randomizer)
      self.model.stage = UiStage::ConfirmingName
      self.model.error_message = None
      self.dirty = true
    }
    UiAction::ConfirmSubmit => {
      self.model.stage = UiStage::Submitting
      self.model.error_message = None
      @game_server.send(self.make_submit_packet())
      self.dirty = true
    }
    UiAction::ConfirmBack => {
      self.model.stage = UiStage::CustomizingLook
      self.dirty = true
    }
  }
}

///|
/// System driving explorer creation UI lifecycle.
pub fn explorer_creation_ui_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase()
    is @game_state.GamePhase::ExplorerCharacterCreation else {
    return
  }

  if creation_ui_ref.val is Some(ui) {
    ui.update()
    return
  }

  guard opening_char_presentation_resource_ref.val is Some(resource) else {
    return
  }
  guard creation_ui_loading_future.val is Some(fut) else {
    creation_ui_loading_future.val = Some(
      @io_service.submit_background_task(async fn() {
        (load_resource(), resource)
      }),
    )
    return
  }

  guard fut.poll() is Some(res) else { return }
  creation_ui_loading_future.val = None
  match res {
    Ok((resource, mod)) => creation_ui_ref.val = Some(new_ui(resource, mod))
    Err(err) => abort("loading explorer creation ui failed: \{err.to_string()}")
  }
}

///|
/// Register server handlers used by explorer creation UI.
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "explorer_creation_result",
    CreateCharacterResultMessage::type_code(),
    json => {
      let message : CreateCharacterResultMessage = @json.from_json(json)
      guard creation_ui_ref.val is Some(ui) else { return }
      if message.success {
        return_to_select_character()
      } else {
        ui.model.stage = UiStage::ConfirmingName
        ui.model.error_message = Some(
          message.error.unwrap_or("Character creation failed"),
        )
        ui.dirty = true
      }
    },
  )
}
