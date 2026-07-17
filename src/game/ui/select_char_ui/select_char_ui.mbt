///|
using @char_look {type CharacterPresentationResource}

///|
using @server_proto {
  type CharacterListMessage,
  type CharacterListRequestMessage,
  type CreateCharacterMessage,
  type CreateCharacterResultMessage,
  type SelectCharMessage,
  type SetFieldMessage,
  type LookEntry,
}

///|

///|
using @game_state {type GamePhase}

///|
struct SelectCharUI {
  characters : Array[SelectableCharacterUI]
  on_new_character : () -> Unit
  // Each segment is (duration seconds, alpha from, alpha to).
  animations : Array[
    (@entity.Entity, Ref[Double], Array[(Double, Double, Double)]),
  ]
  buttons : Array[SeleneButton]
  click_reader : @event.EventReader[@selene_ui.UiClickEvent]
  select_click_entity : @entity.Entity
  new_character_click_entity : @entity.Entity
  entities : Array[@entity.Entity]
}

///|
pub(all) struct SelectCharUIResource {
  /// Animated left light overlay.
  ani17 : @res.SpriteClip
  /// Animated center light overlay.
  ani18 : @res.SpriteClip
  /// Animated right light overlay.
  ani19 : @res.SpriteClip
  /// New-character button state sprites.
  bt_new : @ui.MapleButtonResource
  /// Select-character button state sprites.
  bt_select : @ui.MapleButtonResource
}

///|
let select_char_ui_resource_cache : Ref[SelectCharUIResource?] = Ref(None)

///|
struct SelectableCharacterUI {
  cid : Int
}

///|
priv struct SeleneButton {
  button : @ui.MapleButton
  entity : @entity.Entity
}

///|
pub fn SelectCharUIResource::load() -> SelectCharUIResource {
  match select_char_ui_resource_cache.val {
    Some(resources) => return resources
    None => ()
  }
  let ani18_res : Json = {
    "0": {
      "__h": 442,
      "__w": 432,
      "a0": 100,
      "a1": 255,
      "delay": 2500,
      "origin": [216, 221],
      "z": 0,
      "__i": "res://UI/Login.img/char_select/light18.png",
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
      "__i": "res://UI/Login.img/char_select/light18.png",
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
        "__i": "res://UI/Login.img/char_select/bt_new.png",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [0, 37],
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_new.png",
      },
    },
    "normal": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [0, 0],
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_new.png",
      },
    },
    "pressed": {
      "0": {
        "__h": 37,
        "__w": 110,
        "__off": [110, 0],
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_new.png",
      },
    },
  }
  let ani18 : @res.NxAnimation = @json.from_json(ani18_res) catch {
    _ => abort("invalid select character light animation")
  }
  let bt_select_res : Json = {
    "normal": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_select.png",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_select.png",
      },
    },
    "pressed": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_select.png",
      },
    },
    "disabled": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "res://UI/Login.img/char_select/bt_select.png",
      },
    },
  }
  let bt_new : @ui.NxMapleButton = @json.from_json(bt_new_res) catch {
    _ => abort("invalid select character new button")
  }
  let bt_select : @ui.NxMapleButton = @json.from_json(bt_select_res) catch {
    _ => abort("invalid select character select button")
  }
  let ani17_texture = @res.NxTexture::{
    i: "res://UI/Login.img/char_select/light17.png",
    w: 242,
    h: 505,
    offset: { x: 0, y: 0 },
    origin: { x: 121, y: 252 },
  }
  let ani19_frame0 = @res.NxTexture::{
    i: "res://UI/Login.img/char_select/light19.png",
    w: 312,
    h: 355,
    offset: { x: 0, y: 0 },
    origin: { x: 156, y: 177 },
  }
  let ani19_frame1 = { ..ani19_frame0, offset: { x: 312, y: 0 } }
  let ani17 = @res.compile_nx_animation(
    {
      frames: [
        { texture: ani17_texture, delay: Some(3000), head: None, bounds: None },
        { texture: ani17_texture, delay: Some(3000), head: None, bounds: None },
      ],
      blend: false,
      zigzag: false,
    },
    name="ui/select-char/light-17",
  ) catch {
    error => abort("failed to compile select character light 17: \{error}")
  }
  let ani18 = @res.compile_nx_animation(ani18, name="ui/select-char/light-18") catch {
    error => abort("failed to compile select character light 18: \{error}")
  }
  let ani19 = @res.compile_nx_animation(
    {
      frames: [
        { texture: ani19_frame0, delay: Some(2300), head: None, bounds: None },
        { texture: ani19_frame1, delay: Some(3300), head: None, bounds: None },
        { texture: ani19_frame1, delay: Some(1000), head: None, bounds: None },
      ],
      blend: false,
      zigzag: false,
    },
    name="ui/select-char/light-19",
  ) catch {
    error => abort("failed to compile select character light 19: \{error}")
  }
  let resources = {
    ani17,
    ani18,
    ani19,
    bt_new: @ui.MapleButtonResource::from_nx(bt_new),
    bt_select: @ui.MapleButtonResource::from_nx(bt_select),
  }
  select_char_ui_resource_cache.val = Some(resources)
  resources
}

///|
pub(all) struct SelectableCharacter {
  cid : Int
  name : String
  look : LookEntry
}

///|
pub fn SelectCharUI::SelectCharUI(
  resources : SelectCharUIResource,
  characters : Array[SelectableCharacter],
  resource : CharacterPresentationResource,
  on_select_character? : (Int) -> Unit = fn(_slot) {  },
  on_new_character? : () -> Unit = fn() {  },
) -> SelectCharUI {
  let entities = []
  let background_entity = @entity.Entity()
  @transform2d.set_xy(background_entity, @selene_math.Vec2(0.0, 0.0))
  @sprite.sprites().set(
    background_entity,
    @res.NxTexture::{
      i: "res://UI/Login.img/char_select/back13.png",
      w: 800,
      h: 600,
      offset: { x: 0, y: 0 },
      origin: { x: 0, y: 0 },
    }.require_sprite(),
  )
  entities.push(background_entity)
  let animations : Array[
    (@entity.Entity, Ref[Double], Array[(Double, Double, Double)]),
  ] = []
  for
    item in [
      (
        resources.ani17,
        @selene_math.Vec2(151 - 121, 283 - 252),
        [(3.0, 255.0, 50.0), (3.0, 50.0, 255.0)],
      ),
      (
        resources.ani18,
        @selene_math.Vec2(365 - 216, 252 - 221),
        [(2.5, 100.0, 255.0), (2.5, 255.0, 100.0)],
      ),
      (
        resources.ani19,
        @selene_math.Vec2(191 - 156, 208 - 177),
        [(2.3, 200.0, 80.0), (3.3, 80.0, 255.0), (1.0, 255.0, 200.0)],
      ),
    ] {
    let (clip, position, segments) = item
    let entity = @entity.Entity()
    @transform2d.set_xy(entity, position)
    @sprite.sprites().set(entity, clip.sprite(alpha=segments[0].1 / 255.0))
    @selene_animation.animation_target_ids().set(
      entity,
      @selene_animation.AnimationTargetId("self"),
    )
    @selene_animation.animated_bys().set(
      entity,
      @selene_animation.AnimatedBy(entity),
    )
    let (graph, node) = @graphics.sprite_clip_graph(clip)
    @selene_animation.animation_graph_handles().set(entity, graph)
    let player = @selene_animation.AnimationPlayer()
    @selene_animation.animation_players().set(entity, player)
    ignore(
      player.start(node, repeat=@selene_animation.RepeatAnimation::Forever),
    )
    entities.push(entity)
    animations.push((entity, Ref(0.0), segments))
  }
  for
    item in [
      (
        @res.NxTexture::{
          i: "res://UI/Login.img/char_select/frame.png",
          w: 800,
          h: 600,
          offset: { x: 0, y: 0 },
          origin: { x: 0, y: 0 },
        },
        @selene_math.Vec2(0, 0),
      ),
      (
        @res.NxTexture::{
          i: "res://UI/Login.img/char_select/select_character_btn.png",
          w: 127,
          h: 45,
          offset: { x: 0, y: 0 },
          origin: { x: 0, y: 0 },
        },
        @selene_math.Vec2(40, 0),
      ),
    ] {
    let (texture, pos) = item
    let entity = @entity.Entity()
    @transform2d.set_xy(entity, pos)
    @sprite.sprites().set(entity, texture.require_sprite())
    entities.push(entity)
  }
  let characters_entities = Array::makei(characters.length(), fn(_) {
    @entity.Entity()
  })
  let characters_ui : Array[SelectableCharacterUI] = []
  for i, character in characters {
    let entity = characters_entities[i]
    characters_ui.push(
      to_selectable_character_ui(entity, i, character, resource, entities),
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
    let entity = @entity.Entity()
    entities.push(entity)
    @transform2d.set_xy(entity, @selene_math.Vec2(x.to_double(), y.to_double()))
    let button = MapleButton(res, pos=Point(x, y), on_click~)
    @sprite.sprites().set(entity, button.current_sprite())
    { button, entity }
  }
  let btn_select = spawn_button(entities, resources.bt_select, 601, 393, fn() {
    let slot = 0
    on_select_character(slot)
  })
  let select_click_entity = @entity.Entity()
  entities.push(select_click_entity)
  @selene_ui.nodes().set(
    select_click_entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(601.0, 393.0),
      size=@selene_math.Vec2(
        resources.bt_select.dimensions.x.to_double(),
        resources.bt_select.dimensions.y.to_double(),
      ),
    ),
  )
  @selene_ui.z_indexes().set(select_click_entity, @selene_ui.ZIndex(3000))
  @selene_ui.buttons().set(select_click_entity, @selene_ui.Button())
  @console.register_ui_entity(
    "select_char", "select_character", select_click_entity,
  )
  let new_button_entity = @entity.Entity()
  entities.push(new_button_entity)
  @transform2d.set_xy(new_button_entity, @selene_math.Vec2(200.0, 495.0))
  @sprite.sprites().set(
    new_button_entity,
    resources.bt_new.sprites[@ui.ButtonState::NORMAL],
  )
  let new_click_entity = @entity.Entity()
  entities.push(new_click_entity)
  @selene_ui.nodes().set(
    new_click_entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(200.0, 495.0),
      size=@selene_math.Vec2(
        resources.bt_new.dimensions.x.to_double(),
        resources.bt_new.dimensions.y.to_double(),
      ),
    ),
  )
  @selene_ui.z_indexes().set(new_click_entity, @selene_ui.ZIndex(3000))
  @selene_ui.buttons().set(new_click_entity, @selene_ui.Button())
  @console.register_ui_entity("select_char", "new_character", new_click_entity)
  {
    buttons: [btn_select],
    click_reader: @event.EventReader(),
    select_click_entity,
    new_character_click_entity: new_click_entity,
    entities,
    on_new_character,
    characters: characters_ui,
    animations,
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
  @text2d.text2ds().set(text_entity, @text2d.Text2d())
  @selene_ui.texts().set(text_entity, @selene_ui.Text(name))
  @selene_ui.text_colors().set(
    text_entity,
    @selene_ui.TextColor::from_css("white"),
  )
  @selene_ui.text_fonts().set(text_entity, @game_ui_font.text_font(size=13.0))
  @selene_ui.text_layouts().set(
    text_entity,
    @selene_ui.TextLayout(
      align=@selene_math.HAlign::Center,
      baseline=@selene_math.VAlign::Top,
    ),
  )
}

///|
pub fn load_char_look(
  entity : @entity.Entity,
  resource : @char_look.CharacterPresentationResource,
  character : SelectableCharacter,
) -> @char_look.CharLook {
  let look = character.look
  let body = resource.load_body_by_skin_id(look.skin)
  let hair = resource.load_hair_by_id(look.hairid)
  let face = resource.load_face_by_id(look.faceid)
  @char_look.CharLook::load(entity, look, body, hair, face, resource.draw_info)
}

///|
pub fn to_selectable_character_ui(
  entity : @entity.Entity,
  i : Int,
  character : SelectableCharacter,
  resource : CharacterPresentationResource,
  entities : Array[@entity.Entity],
) -> SelectableCharacterUI {
  let char_look = load_char_look(entity, resource, character)
  let { cid, name, .. } = character
  @transform2d.set_xy(entity, get_character_slot_pos(i, 135, 234).to_vec2d())
  char_look.set_stance(@char_stance.StanceId::STAND1)
  char_look.set_facing_right(true)
  char_look.play_animations()
  spawn_character_name_entity(entity, name, entities)
  { cid, }
}

///|
fn get_character_slot_pos(
  index : Int,
  x_adj : Int,
  y_adj : Int,
) -> @struct.Point[Int] {
  let x = 125 * (index % 4)
  let y = 200 * (index > 3).to_int()
  return Point(x + x_adj, y + y_adj)
}

///|
let select_char_ui : Ref[SelectCharUI?] = Ref(None)

///|
fn SelectCharUI::destroy(self : SelectCharUI) -> Unit {
  @console.unregister_ui_entity(self.select_click_entity)
  @console.unregister_ui_entity(self.new_character_click_entity)
  for entity in self.entities {
    @graphics.clear_sprite_animation(entity)
    @transform2d.remove(entity) |> ignore
    if entity.is_alive() {
      entity.destroy()
    }
  }
}

///|
let character_list_ref : Ref[Array[SelectableCharacter]?] = Ref(None)

///|
let character_list_requested_ref : Ref[Bool] = Ref(false)

///|
let select_char_requested_ref : Ref[Bool] = Ref(false)

///|
let char_name_counter_ref : Ref[Int] = Ref(0)

///|
fn send_select_char_once(character_id : Int) -> Unit {
  if select_char_requested_ref.val {
    return
  }
  select_char_requested_ref.val = true
  @game_server.send(SelectCharMessage::{ character_id, })
}

///|
fn init {
  @console.register_command("new_character", fn(_args) {
    guard select_char_ui.val is Some(ui) else {
      return {
        "ok": false,
        "code": "SELECT_CHAR_UI_NOT_READY",
        "message": "select character UI is not ready",
      }
    }
    (ui.on_new_character)()
    { "ok": true, "code": "CREATE_CHARACTER_SENT" }
  })
  @console.register_command("select_char", fn(args) {
    let slot = if args.length() > 0 {
      @string.parse_int(args[0]) catch {
        _ => 0
      }
    } else {
      0
    }
    guard select_char_ui.val is Some(ui) else {
      return {
        "ok": false,
        "code": "SELECT_CHAR_UI_NOT_READY",
        "message": "select character UI is not ready",
      }
    }
    guard slot >= 0 && slot < ui.characters.length() else {
      return {
        "ok": false,
        "code": "INVALID_SLOT",
        "slot": slot,
        "slot_count": ui.characters.length(),
      }
    }
    guard !select_char_requested_ref.val else {
      return { "ok": false, "code": "SELECT_CHAR_ALREADY_REQUESTED" }
    }
    let character_id = ui.characters[slot].cid
    send_select_char_once(character_id)
    {
      "ok": true,
      "code": "SELECT_CHAR_SENT",
      "slot": slot,
      "character_id": character_id,
    }
  })
  @console.register_command("char_list", fn(_args) {
    guard character_list_ref.val is Some(chars) else {
      return { "ok": false, "message": "character list not available" }
    }
    let list : Array[Json] = []
    for i, c in chars {
      list.push({ "slot": i, "name": c.name, "cid": c.cid })
    }
    { "ok": true, "characters": list.to_json() }
  })
}

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
  select_char_requested_ref.val = false
}

///|
fn add_select_char_ui(
  resource : CharacterPresentationResource,
  slots : Array[SelectableCharacter],
) -> SelectCharUI {
  SelectCharUI(
    SelectCharUIResource::load(),
    slots,
    on_select_character=fn(slot) {
      guard select_char_ui.val is Some(ui) else { return }
      guard slot >= 0 && slot < ui.characters.length() else { return }
      send_select_char_once(ui.characters[slot].cid)
    },
    on_new_character=fn() {
      char_name_counter_ref.val = char_name_counter_ref.val + 1
      let name = "explorer" + char_name_counter_ref.val.to_string()
      @game_server.send(CreateCharacterMessage::{
        name,
        job: 1,
        face: 20000,
        hair: 30030,
        hairc: 0,
        skin: 0,
        top: 1040002,
        bot: 1060002,
        shoes: 1072001,
        weapon: 1302000,
        female: false,
      })
    },
    resource,
  )
}

///|
let select_char_loading_future : Ref[
  @utils.Future[Result[SelectCharUI, Error]]?,
] = Ref(None)

///|
pub fn select_char_ui_system(_world : @ecs.World) -> Unit {
  guard @char_look.get_resource() is Some(resource) else { return }
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
      @sprite.sprites().set(button.entity, button.button.current_sprite())
    }
    for item in ui.animations {
      let (entity, elapsed, segments) = item
      let mut total = 0.0
      for seg in segments {
        total += seg.0
      }
      guard total > 0.0 else {
        abort("select character light animation duration must be positive")
      }
      elapsed.val = (elapsed.val + @time.delta()) % total
      let mut acc = 0.0
      let mut alpha_val = 255.0
      for seg in segments {
        let dur = seg.0
        let from = seg.1
        let to = seg.2
        if elapsed.val < acc + dur {
          let t = (elapsed.val - acc) / dur
          alpha_val = from + (to - from) * t
          break
        }
        acc += dur
      }
      let alpha_norm = alpha_val / 255.0
      if @sprite.sprites().get(entity) is Some(sprite) {
        @sprite.sprites().set(entity, {
          ..sprite,
          color: { ..sprite.color, a: alpha_norm },
        })
      }
    }
    let click_events = @selene_ui.click_event_bus.read(ui.click_reader)
    for event in click_events {
      guard event.button is @inputs.MouseButton::Left else { continue }
      if event.entity == ui.select_click_entity {
        let slot = 0
        guard slot >= 0 && slot < ui.characters.length() else { break }
        send_select_char_once(ui.characters[slot].cid)
        break
      }
      if event.entity == ui.new_character_click_entity {
        (ui.on_new_character)()
        break
      }
    }
    return
  }

  guard character_list_ref.val is Some(characters) else {
    if !character_list_requested_ref.val {
      character_list_requested_ref.val = true
      @game_server.send(CharacterListRequestMessage(()))
    }
    return
  }

  // If not loading yet, start background task
  guard select_char_loading_future.val is Some(fut) else {
    select_char_loading_future.val = Some(
      @io_service.submit_background_task(() => {
        add_select_char_ui(resource, characters)
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
/// Register server message handlers used by the select-character UI.
///
/// The select-character runtime state is reset before registration so repeated
/// test setups start from the same empty UI state.
pub fn setup_game_server_handlers() -> Unit {
  reset_select_char_ui_runtime_state()
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
      select_char_requested_ref.val = false
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
  @game_server.add_server_message_handler(
    "select_char_create_result",
    CreateCharacterResultMessage::type_code(),
    json => {
      let message : CreateCharacterResultMessage = @json.from_json(json)
      if message.success {
        character_list_ref.val = None
        character_list_requested_ref.val = false
        clear_select_char_ui_runtime()
      }
    },
  )
}

///|
using @ui {type MapleButton}
