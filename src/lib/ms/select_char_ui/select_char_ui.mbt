///|
using @char_look {type CharLookMod}

///|
using @server_proto {
  type CharacterListMessage,
  type CharacterListRequestMessage,
  type SelectCharMessage,
  type SetFieldMessage,
}

///|
using @explorer_creation_ui {open_explorer_creation_ui}

///|
using @game_state {type GamePhase}

///|
struct SelectCharUI {
  characters : Array[SelectableCharacterUI]
  on_new_character : () -> Unit
  select_slot : Int?
  resource : SelectCharUIResource
  // 以数组配置驱动三段光照动画，减少重复代码
  // 每项：(entity, frame_counter_ref, segments)
  // segment: (duration_frames, from_alpha, to_alpha)
  animations : Array[(@entity.Entity, Ref[Int], Array[(Int, Double, Double)])]
  buttons : Array[SeleneButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  new_character_click_entity : @entity.Entity
  entities : Array[@entity.Entity]
}

///|
pub(all) struct SelectCharUIResource {
  ani18 : @ms_animation.Animation
  bt_new : @ui.MapleButtonResource
  bt_select : @ui.MapleButtonResource
}

///|
struct SelectableCharacterUI {
  cid : Int
  char_look : @char_look.CharLook
  name : String
}

///|
priv struct SeleneButton {
  button : @ui.MapleButton
  entity : @entity.Entity
}

///|
pub fn SelectCharUIResource::load() -> SelectCharUIResource raise {
  let ani18_res : Json = {
    "0": {
      "__h": 442,
      "__w": 432,
      "a0": 100,
      "a1": 255,
      "delay": 2500,
      "origin": [216, 221],
      "z": 0,
      "__i": "/assets/ui/login.img/char_select/light18.png",
    },
    "1": {
      "__h": 442,
      "__w": 432,
      "_inlink": "ani/18/0",
      "a0": 255,
      "a1": 100,
      "delay": 2500,
      "origin": [216, 221],
      "z": 0,
      "__i": "/assets/ui/login.img/char_select/light18.png",
    },
  }
  let bt_new_res : Json = {
    "disabled": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [110, 37],
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_new.png",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [0, 37],
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_new.png",
      },
    },
    "normal": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [0, 0],
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_new.png",
      },
    },
    "pressed": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [110, 0],
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_new.png",
      },
    },
  }
  let ani18 : @resource.NxAnimation = @json.from_json(ani18_res)
  let bt_select_res : Json = {
    "normal": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_select.png",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_select.png",
      },
    },
    "pressed": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_select.png",
      },
    },
    "disabled": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/bt_select.png",
      },
    },
  }
  let bt_new : @ui.NxMapleButton = @json.from_json(bt_new_res)
  let bt_select : @ui.NxMapleButton = @json.from_json(bt_select_res)
  {
    ani18: @ms_animation.from_nx_animation(ani18),
    bt_new: @ui.MapleButtonResource::from_nx(bt_new),
    bt_select: @ui.MapleButtonResource::from_nx(bt_select),
  }
}

///|
pub(all) struct SelectableCharacter {
  cid : Int
  name : String
  look : @char_look.LookEntry
}

///|
pub async fn SelectCharUI::new(
  resources : SelectCharUIResource,
  characters : Array[SelectableCharacter],
  mod : CharLookMod,
  on_select_character? : (Int) -> Unit = fn(_slot) {  },
  on_new_character? : () -> Unit = fn() {  },
) -> SelectCharUI {
  let back13 = @ms_animation.Animation::single_frame(
    "/assets/ui/login.img/char_select/back13.png",
    @selene_math.Vec2D(800, 600),
    //   "origin": [392, 297]
  )
  let ani17 = @ms_animation.Animation::new([
    @ms_animation.AnimationFrame::{
      image: @asset.load_image("/assets/ui/login.img/char_select/light17.png"),
      size: @selene_math.Vec2D(505, 242),
      offset: @selene_math.Vec2D(0, 0),
      pivot: @selene_math.Vec2D(121, 252), // origin
      duration: 3.0,
      //     "origin": [121, 252],
      //     "a0": 255,
      //     "a1": 50,
      //     "delay": 3000,
    },
    @ms_animation.AnimationFrame::{
      image: @asset.load_image("/assets/ui/login.img/char_select/light17.png"),
      size: @selene_math.Vec2D(505, 242),
      offset: @selene_math.Vec2D(0, 0),
      pivot: @selene_math.Vec2D(121, 252), // origin
      duration: 3.0,
      //     "origin": [121, 252],
      //     "a0": 50,
      //     "a1": 255,
      //     "delay": 3000,
    },
  ])
  let ani19 : @ms_animation.Animation = @ms_animation.Animation::new([
    @ms_animation.AnimationFrame::{
      image: @asset.load_image("/assets/ui/login.img/char_select/light19.png"),
      size: @selene_math.Vec2D(355, 312),
      offset: @selene_math.Vec2D(0, 0),
      pivot: @selene_math.Vec2D(156, 177), // origin
      duration: 2.3,
      //     "origin": [156, 177],
      //     "a0": 200,
      //     "a1": 80,
      //     "delay": 2300,
      // "origin": [156, 177],
    },
    @ms_animation.AnimationFrame::{
      image: @asset.load_image("/assets/ui/login.img/char_select/light19.png"),
      offset: @selene_math.Vec2D(312, 0),
      size: @selene_math.Vec2D(355, 312),
      pivot: @selene_math.Vec2D(156, 177), // origin
      duration: 3.3,
      // "a0": 80,
      // "a1": 255,
      // "delay": 3300,
      // "origin": [156, 177],
    },
    @ms_animation.AnimationFrame::{
      image: @asset.load_image("/assets/ui/login.img/char_select/light19.png"),
      offset: @selene_math.Vec2D(312, 0),
      size: @selene_math.Vec2D(355, 312),
      pivot: @selene_math.Vec2D(156, 177), // origin
      duration: 1.0,
      // "_inlink": "ani/19/1",
      // "a0": 255,
      // "a1": 200,
      // "delay": 1000,
      // "origin": [156, 177],
    },
  ])
  let frame = @ms_animation.Animation::single_frame(
    "/assets/ui/login.img/char_select/frame.png",
    @selene_math.Vec2D(800, 600),
    //   "origin": [400, 300]
  )
  let step2 = @ms_animation.Animation::single_frame(
    "/assets/ui/login.img/char_select/select_character_btn.png",
    @selene_math.Vec2D(127, 45),
    //   "origin": [0, 0]
  )
  let entities = []
  for
    t in [
      (back13, @selene_math.Vec2D(0, 0)),
      (ani17, @selene_math.Vec2D(151 - 121, 283 - 252)), //   "origin": [121, 252],
      (resources.ani18, @selene_math.Vec2D(365 - 216, 252 - 221)), // "origin": [216, 221],
      (ani19, @selene_math.Vec2D(191 - 156, 208 - 177)), // "origin": [156, 177],
      (frame, @selene_math.Vec2D(0, 0)),
      (step2, @selene_math.Vec2D(40, 0)),
    ] {
    let (s, pos) = t
    let entity = @entity.Entity::new()
    @transform2d.set_xy(entity, pos)
    @sprite.sprites().set(entity, @ms_animation.sprite_from_animation(s, 0))
    entities.push(entity)
  }
  let characters_entities = Array::makei(characters.length(), fn(_) {
    @entity.Entity::new()
  })
  let characters_ui : Array[SelectableCharacterUI] = []
  for i, character in characters {
    let entity = characters_entities[i]
    characters_ui.push(
      to_selectable_character_ui(entity, i, character, mod, entities),
    )
  }
  entities.append(characters_entities)
  fn spawn_button(
    entities : Array[@entity.Entity],
    res : @ui.MapleButtonResource,
    x : Int,
    y : Int,
    on_click : () -> Unit,
  ) -> SeleneButton {
    let entity = @entity.Entity::new()
    entities.push(entity)
    @transform2d.set_xy(
      entity,
      @selene_math.Vec2D(x.to_double(), y.to_double()),
    )
    let button = @ui.MapleButton::new(
      res,
      pos=@struct.Point::new(x, y),
      on_click~,
    )
    @sprite.sprites().set(
      entity,
      @ms_animation.sprite_from_animation(button.current_selene_animation(), 10),
    )
    { button, entity }
  }
  let btn_select = spawn_button(entities, resources.bt_select, 601, 393, fn() {
    let slot = 0
    on_select_character(slot)
  })
  let new_button_entity = @entity.Entity::new()
  entities.push(new_button_entity)
  @transform2d.set_xy(new_button_entity, @selene_math.Vec2D(200.0, 495.0))
  @sprite.sprites().set(
    new_button_entity,
    @ms_animation.sprite_from_animation(
      resources.bt_new.selene_animations[@ui.ButtonState::NORMAL],
      10,
    ),
  )
  let new_click_entity = @entity.Entity::new()
  entities.push(new_click_entity)
  @selene_ui.nodes().set(
    new_click_entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(200.0, 495.0),
      size=@selene_math.Vec2D(
        resources.bt_new.dimensions.x.to_double(),
        resources.bt_new.dimensions.y.to_double(),
      ),
    ),
  )
  @selene_ui.z_indexes().set(new_click_entity, @selene_ui.ZIndex::new(3000))
  @selene_ui.buttons().set(new_click_entity, @selene_ui.Button::new())
  @console.register_ui_entity("select_char", "new_character", new_click_entity)
  {
    buttons: [btn_select],
    click_reader: @event.EventReader::new(),
    new_character_click_entity: new_click_entity,
    entities,
    select_slot: None,
    on_new_character,
    characters: characters_ui,
    resource: resources,
    animations: [
      // ani17: 255->50 (3s=180f), 50->255 (3s=180f)
      (entities[1], Ref::new(0), [(180, 255.0, 50.0), (180, 50.0, 255.0)]),
      // ani18: 100->255 (2.5s=150f), 255->100 (2.5s=150f)
      (entities[2], Ref::new(0), [(150, 100.0, 255.0), (150, 255.0, 100.0)]),
      // ani19: 200->80 (2.3s=138f), 80->255 (3.3s=198f), 255->200 (1s=60f)
      (
        entities[3],
        Ref::new(0),
        [(138, 200.0, 80.0), (198, 80.0, 255.0), (60, 255.0, 200.0)],
      ),
    ],
  }
}

///|
fn spawn_character_name_entity(
  parent : @entity.Entity,
  name : String,
  entities : Array[@entity.Entity],
) -> Unit {
  let text_entity = parent.spawn_child()
  @transform.transforms().set(
    text_entity,
    @transform.Transform::from_xyz(0.0, 54.0, 10.0),
  )
  entities.push(text_entity)
  @text2d.text2ds().set(text_entity, @text2d.Text2d::new())
  @selene_ui.texts().set(text_entity, @selene_ui.Text::new(name))
  @selene_ui.text_colors().set(
    text_entity,
    @selene_ui.TextColor::from_css("white"),
  )
  @selene_ui.text_fonts().set(
    text_entity,
    @selene_ui.TextFont::from_css("13px Arial"),
  )
  @selene_ui.text_layouts().set(
    text_entity,
    @selene_ui.TextLayout::new(
      align=@selene_math.HAlign::Center,
      baseline=@selene_math.VAlign::Top,
    ),
  )
}

///|
pub async fn load_char_look(
  entity : @entity.Entity,
  mod : @char_look.CharLookMod,
  character : SelectableCharacter,
) -> @char_look.CharLook {
  let look = character.look
  let body = mod.load_body_by_skin_id(look.skin)
  let hair = mod.load_hair_by_id(look.hairid)
  let face = mod.load_face_by_id(look.faceid)
  @char_look.CharLook::load(entity, look, body, hair, face, mod.draw_info)
}

///|
pub async fn to_selectable_character_ui(
  entity : @entity.Entity,
  i : Int,
  character : SelectableCharacter,
  mod : CharLookMod,
  entities : Array[@entity.Entity],
) -> SelectableCharacterUI {
  let char_look = load_char_look(entity, mod, character)
  let { cid, name, .. } = character
  @transform2d.set_xy(entity, get_character_slot_pos(i, 135, 234).to_vec2d())
  char_look.set_stance(@char_stance.StanceId::STAND1)
  char_look.set_facing_right(true)
  char_look.play_animations()
  spawn_character_name_entity(entity, name, entities)
  { cid, char_look, name }
}

///|
fn get_character_slot_pos(
  index : Int,
  x_adj : Int,
  y_adj : Int,
) -> @struct.Point[Int] {
  let x = 125 * (index % 4)
  let y = 200 * (index > 3).to_int()
  return @struct.Point::new(x + x_adj, y + y_adj)
}

///|
let select_char_ui : Ref[SelectCharUI?] = Ref::new(None)

///|
fn SelectCharUI::destroy(self : SelectCharUI) -> Unit {
  @console.unregister_ui_entity(self.new_character_click_entity)
  for entity in self.entities {
    entity.destroy()
  }
}

///|
let character_list_ref : Ref[Array[SelectableCharacter]?] = Ref::new(None)

///|
let character_list_requested_ref : Ref[Bool] = Ref::new(false)

///|
fn clear_select_char_ui_runtime() -> Unit {
  select_char_loading_future.val = None
  match select_char_ui.val {
    Some(ui) => {
      select_char_ui.val = None
      ui.destroy()
    }
    None => ()
  }
}

///|
fn reset_select_char_ui_runtime_state() -> Unit {
  clear_select_char_ui_runtime()
  character_list_ref.val = None
  character_list_requested_ref.val = false
}

///|
async fn add_select_char_ui(
  mod : CharLookMod,
  slots : Array[SelectableCharacter],
) -> SelectCharUI {
  SelectCharUI::new(
    SelectCharUIResource::load(),
    slots,
    on_select_character=fn(slot) {
      guard select_char_ui.val is Some(ui) else { return }
      @game_server.send(SelectCharMessage::{
        character_id: ui.characters[slot].cid,
      })
    },
    on_new_character=fn() {
      reset_select_char_ui_runtime_state()
      @game_state.set_next_phase(
        @game_state.GamePhase::ExplorerCharacterCreation,
      )
      open_explorer_creation_ui(mod)
    },
    mod,
  )
}

///|
let select_char_loading_future : Ref[
  @utils.Future[Result[SelectCharUI, Error]]?,
] = Ref::new(None)

///|
pub fn select_char_ui_system(_world : @ecs.World) -> Unit {
  guard @char_look.get_module() is Some(mod) else { return }
  guard @game_state.current_phase() is GamePhase::SelectCharacter else {
    reset_select_char_ui_runtime_state()
    return
  }

  // If UI is already loaded, update animations
  if select_char_ui.val is Some(ui) {
    let mouse_pos = @inputs.mouse.pos
    let mouse_x = mouse_pos[@selene_math.X].to_int()
    let mouse_y = mouse_pos[@selene_math.Y].to_int()
    let is_pressed = @inputs.is_mouse_pressed(@inputs.MouseButton::Left)
    let just_pressed = @inputs.is_mouse_just_pressed(@inputs.MouseButton::Left)
    let just_released = @inputs.is_mouse_just_released(
      @inputs.MouseButton::Left,
    )
    for button in ui.buttons {
      button.button.update_pointer(
        mouse_x, mouse_y, is_pressed, just_pressed, just_released,
      )
      @sprite.sprites().set(
        button.entity,
        @ms_animation.sprite_from_animation(
          button.button.current_selene_animation(),
          10,
        ),
      )
    }
    for item in ui.animations {
      let (entity, counter, segments) = item
      // 计算总帧数
      let mut total = 0
      for seg in segments {
        total += seg.0
      }
      // 推进计数
      counter.val = (counter.val + 1) % total
      let p = counter.val
      // 定位当前段
      let mut acc = 0
      let mut alpha_val = 255.0
      for seg in segments {
        let dur = seg.0
        let from = seg.1
        let to = seg.2
        if p < acc + dur {
          let t = (p - acc).to_double() / dur.to_double()
          alpha_val = from + (to - from) * t
          break
        }
        acc += dur
      }
      let alpha_norm = alpha_val / 255.0
      // if @sprite.sprites().get(entity) is Some(spr) {
      //   @sprite.sprites().set(entity, { ..spr, alpha: alpha_norm })
      // }
      // TODO: modify upstream selene to support alpha
      ignore(entity)
      ignore(alpha_norm)
    }
    let click_events = @selene_ui.click_event_bus.read(ui.click_reader)
    for event in click_events {
      guard event.button is @inputs.MouseButton::Left else { continue }
      if event.entity == ui.new_character_click_entity {
        (ui.on_new_character)()
        break
      }
    }
    return
  }

  guard character_list_ref.val is Some(characters) else {
    if not(character_list_requested_ref.val) {
      character_list_requested_ref.val = true
      @game_server.send(CharacterListRequestMessage::default())
    }
    return
  }

  // If not loading yet, start background task
  guard select_char_loading_future.val is Some(fut) else {
    select_char_loading_future.val = Some(
      @io_service.submit_background_task(() => {
        add_select_char_ui(mod, characters)
      }),
    )
    return
  }

  // Poll for completion
  guard fut.poll() is Some(res) else { return }

  // Process result
  select_char_loading_future.val = None
  match res {
    Ok(ui) => select_char_ui.val = Some(ui)
    Err(e) => abort("add select char ui failed: \{e.to_string()}")
  }
}

///|
/// Returns whether select-character UI is currently mounted.
pub fn is_select_char_ui_open() -> Bool {
  select_char_ui.val is Some(_)
}

///|
fn init {
  @console.register_state_section("select_char", fn() {
    { "open": is_select_char_ui_open() }
  })
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "select_char_list",
    CharacterListMessage::type_code(),
    json => {
      let message : CharacterListMessage = @json.from_json(json)
      character_list_ref.val = Some(
        message.characters.map(fn(character) {
          {
            cid: character.character_id,
            name: character.name,
            look: character.look,
          }
        }),
      )
      character_list_requested_ref.val = false
      clear_select_char_ui_runtime()
    },
  )
  @game_server.add_server_message_handler(
    "select_char",
    @server_proto.Opcode::SET_FIELD.int_value(),
    json => {
      let set_field_message : SetFieldMessage = @json.from_json(json)
      guard set_field_message is SetField(stats={ map_id, portal_id, .. }, ..) else {
        return
      }
      guard select_char_ui.val is Some(_) else { return }
      @game_state.set_next_phase(
        @game_state.GamePhase::GameStart(
          map_id~,
          portal_id~,
          set_field_message~,
        ),
      )
      reset_select_char_ui_runtime_state()
    },
  )
}
