///|
using @resource {nx_animation_to_selene_animation}

///|
using @char_look {type CharLookMod, type CharLook}

///|
using @io_service {execute_background}

///|
using @maple_protocol {type SetFieldMessage, type SelectCharMessage}

///|
using @game_state {type GamePhase, game_state}

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
  btn_select : @ui.MapleButton
  entities : Array[@entity.Entity]
}

///|
pub(all) struct SelectCharUIResource {
  name_tag : @ui.NameTagResource
  ani18 : @sprite.Animation
}

///|
struct SelectableCharacterUI {
  cid : Int
  char_look : @char_look.CharLook
  name_tag : @ui.NameTag
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
  let name_tag_res : Json = {
    "0": {
      "0": {
        "__h": 23,
        "__w": 6,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 23,
        "__w": 1,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [12, 0],
      },
      "2": {
        "__h": 23,
        "__w": 6,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [6, 0],
      },
    },
    "1": {
      "0": {
        "__h": 23,
        "__w": 6,
        // "_inlink": "CharSelect/nameTag/0/0",
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 23,
        "__w": 1,
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [13, 0],
      },
      "2": {
        "__h": 23,
        "__w": 6,
        // "_inlink": "CharSelect/nameTag/0/2",
        "origin": [0, 0],
        "z": 0,
        "__i": "/assets/ui/login.img/char_select/name_tag.png",
        "__off": [6, 0],
      },
    },
  }
  // let bt_new_res : Json = {
  //   "disabled": {
  //     "0": {
  //       "__h": 37,
  //       "__w": 110,
  //       "origin": [0, 0],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28164",
  //     },
  //   },
  //   "keyFocused": {
  //     "0": {
  //       "__h": 25,
  //       "__w": 35,
  //       "origin": [-85, 17],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //     "1": {
  //       "__h": 25,
  //       "__w": 35,
  //       "_inlink": "CharSelect/BtNew/keyFocused/0",
  //       "delay": "50",
  //       "origin": [-85, 16],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //     "2": {
  //       "__h": 25,
  //       "__w": 35,
  //       "_inlink": "CharSelect/BtNew/keyFocused/0",
  //       "delay": "50",
  //       "origin": [-85, 15],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //     "3": {
  //       "__h": 25,
  //       "__w": 35,
  //       "_inlink": "CharSelect/BtNew/keyFocused/0",
  //       "delay": "50",
  //       "origin": [-85, 14],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //     "4": {
  //       "__h": 25,
  //       "__w": 35,
  //       "_inlink": "CharSelect/BtNew/keyFocused/0",
  //       "delay": "50",
  //       "origin": [-85, 15],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //     "5": {
  //       "__h": 25,
  //       "__w": 35,
  //       "_inlink": "CharSelect/BtNew/keyFocused/0",
  //       "delay": "50",
  //       "origin": [-85, 16],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
  //     },
  //   },
  //   "mouseOver": {
  //     "0": {
  //       "__h": 37,
  //       "__w": 110,
  //       "origin": [0, 0],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28162",
  //     },
  //   },
  //   "normal": {
  //     "0": {
  //       "__h": 37,
  //       "__w": 110,
  //       "origin": [0, 0],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28161",
  //     },
  //   },
  //   "pressed": {
  //     "0": {
  //       "__h": 37,
  //       "__w": 110,
  //       "origin": [0, 0],
  //       "z": 0,
  //       "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28163",
  //     },
  //   },
  // }
  let ani18 : @resource.NxAnimation = @json.from_json(ani18_res)
  {
    name_tag: @json.from_json(name_tag_res),
    // bt_new: @json.from_json(bt_new_res),
    ani18: nx_animation_to_selene_animation(ani18),
  }
}

///|
pub(all) struct SelectableCharacter {
  cid : Int
  // char_look : @char_look.CharLook
  name : String
}

///|
pub async fn SelectCharUI::new(
  resources : SelectCharUIResource,
  characters : Array[SelectableCharacter],
  mod : CharLookMod,
  on_select_character? : (Int) -> Unit = fn(_slot) {  },
  on_new_character? : () -> Unit = fn() {  },
) -> SelectCharUI {
  // ui_model.dimension = @struct.Point::new(800, 600)

  let back13 = @sprite.Animation::single_frame(
    "/assets/ui/login.img/char_select/back13.png",
    @selene_math.Vec2D(800, 600),
    //   "origin": [392, 297],
  )
  let ani17 = @sprite.Animation::new([
    @sprite.AnimationFrame::{
      sprite_path: "/assets/ui/login.img/char_select/light17.png",
      size: @selene_math.Vec2D(505, 242),
      offset: @selene_math.Vec2D(0, 0),
      pivot: @selene_math.Vec2D(121, 252), // origin
      duration: 3.0,
      //     "origin": [121, 252],
      //     "a0": 255,
      //     "a1": 50,
      //     "delay": 3000,
    },
    @sprite.AnimationFrame::{
      sprite_path: "/assets/ui/login.img/char_select/light17.png",
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
  let ani19 : @sprite.Animation = @sprite.Animation::new([
    @sprite.AnimationFrame::{
      sprite_path: "/assets/ui/login.img/char_select/light19.png",
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
    @sprite.AnimationFrame::{
      sprite_path: "/assets/ui/login.img/char_select/light19.png",
      offset: @selene_math.Vec2D(312, 0),
      size: @selene_math.Vec2D(355, 312),
      pivot: @selene_math.Vec2D(156, 177), // origin
      duration: 3.3,
      // "a0": 80,
      // "a1": 255,
      // "delay": 3300,
      // "origin": [156, 177],
    },
    @sprite.AnimationFrame::{
      sprite_path: "/assets/ui/login.img/char_select/light19.png",
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
  let frame = @sprite.Animation::single_frame(
    "/assets/ui/login.img/char_select/frame.png",
    @selene_math.Vec2D(800, 600),
    //   "origin": [400, 300],
  )
  let step2 = @sprite.Animation::single_frame(
    "/assets/ui/login.img/char_select/select_character_btn.png",
    @selene_math.Vec2D(127, 45),
    //   "origin": [0, 0],
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
    @position.positions.set(entity, @position.Position(pos))
    @selene_ui.uis.set(entity, @selene_ui.Ui::new())
    @sprite.sprites.set(entity, @sprite.Sprite::from_animation(s, 0))
    entities.push(entity)
  }
  let characters_entities = Array::makei(characters.length(), fn(_) {
    @entity.Entity::new()
  })
  let characters_ui : Array[SelectableCharacterUI] = []
  for i, character in characters {
    let entity = characters_entities[i]
    characters_ui.push(
      to_selectable_character_ui(entity, i, character, resources, mod),
    )
  }
  entities.append(characters_entities)
  let res : Map[@ui.ButtonState, @resource.NxAnimation] = {}
  res[NORMAL] = {
    frames: [
      {
        texture: {
          i: "/assets/ui/login.img/char_select/bt_select.png",
          w: 140,
          h: 52,
          offset: @struct.Point::new(0, 0),
          origin: @struct.Point::new(0, 0),
        },
        delay: None,
        head: None,
        bounds: None,
      },
    ],
    blend: false,
    zigzag: false,
  }
  res[MOUSEOVER] = {
    frames: [
      {
        texture: {
          i: "/assets/ui/login.img/char_select/bt_select.png",
          w: 140,
          h: 52,
          offset: @struct.Point::new(140, 0),
          origin: @struct.Point::new(0, 0),
        },
        delay: None,
        head: None,
        bounds: None,
      },
    ],
    blend: false,
    zigzag: false,
  }
  res[PRESSED] = {
    frames: [
      {
        texture: {
          i: "/assets/ui/login.img/char_select/bt_select.png",
          w: 140,
          h: 52,
          offset: @struct.Point::new(280, 0),
          origin: @struct.Point::new(0, 0),
        },
        delay: None,
        head: None,
        bounds: None,
      },
    ],
    blend: false,
    zigzag: false,
  }
  res[DISABLED] = {
    frames: [
      {
        texture: {
          i: "/assets/ui/login.img/char_select/bt_select.png",
          w: 140,
          h: 52,
          offset: @struct.Point::new(420, 0),
          origin: @struct.Point::new(0, 0),
        },
        delay: None,
        head: None,
        bounds: None,
      },
    ],
    blend: false,
    zigzag: false,
  }
  let btn_select = @ui.MapleButton::new(
    @ui.MapleButtonResource(res),
    pos=@struct.Point::new(601, 393),
    on_click=fn() {
      // guard self.select_slot is Some(slot) else { return None }
      let slot = 0 // TODO: get slot from UI
      on_select_character(slot)
    },
  )
  // render_elements.push(
  //   @ui.MapleButton::new(resources.bt_new, pos=@struct.Point::new(200, 495))
  //   |> @ui.Button::new(on_click=fn() {
  //     (self.on_new_character)()
  //     None
  //   })
  //   |> @ui.Button::as_interactable,
  // )
  {
    btn_select,
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
pub async fn load_char_look(
  entity : @entity.Entity,
  mod : @char_look.CharLookMod,
  _character : SelectableCharacter, // TODO: use character look data
) -> @char_look.CharLook {
  let draw_info = mod.draw_info
  let stance_bodys_map = mod.stance_bodys_map.0
  let stance_heads_map = mod.stance_heads_map.0
  let hair = @char_look.Hair::load(30030, draw_info)
  let face = @char_look.Face::load(20000)
  @char_look.CharLook::new(
    entity,
    {},
    @char_look.FullBody::new(0, draw_info, stance_bodys_map, stance_heads_map),
    hair,
    face,
    draw_info,
  )
}

///|
pub async fn to_selectable_character_ui(
  entity : @entity.Entity,
  i : Int,
  character : SelectableCharacter,
  resource : SelectCharUIResource,
  mod : CharLookMod,
) -> SelectableCharacterUI {
  let char_look = load_char_look(entity, mod, character)
  let { cid, name } = character
  // render_elements.push(
  //   @ui.AreaButton::new(
  //     get_character_slot_pos(i, 105, 144),
  //     @struct.Point::new(50, 90),
  //   )
  //   |> @ui.Button::new(on_click=fn() {
  //     self.select_slot = Some(i)
  //     // (self.hooks.on_state_changed)()
  //     None
  //   })
  //   |> @ui.Button::as_interactable,
  // )
  char_look.set_stance(StanceId::STAND1)
  char_look.set_facing_right(true)
  char_look.play_animations()
  @position.positions.set(
    entity,
    @position.Position(get_character_slot_pos(i, 135, 234).to_vec2d()),
  )
  // name_tag.set_selected(Some(i) == self.select_slot)
  // render_elements.push(
  //   @ui.StaticUI::new(name_tag, pos=get_character_slot_pos(i, 135, 234))
  //   |> @ui.RenderElement::Static,
  // )
  {
    cid,
    char_look,
    name_tag: @ui.NameTag::new(@graphics.FontId::A13M, name, resource.name_tag),
  }
}

///|
struct CharLookUI {
  char_look : @char_look.CharLook
  pos : @struct.Point[Int]
}

///|
impl @graphics.Drawable for CharLookUI with draw(self, _) -> Unit {
  self.char_look.draw(@graphics.DrawArgument::new(pos=self.pos), 0)
}

///|
impl @ui.RenderUnit for CharLookUI with update(self) -> Unit {
  ignore(self)
  // self.char_look.update(@config.step_time_ms) |> ignore
}

///|
pub impl ToJson for CharLookUI with to_json(self) -> Json {
  { "char_look": self.char_look.to_json(), "pos": self.pos.to_json() }
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
const PAGE_SIZE = 8

///|
let select_char_ui : Ref[SelectCharUI?] = Ref::new(None)

///|
fn SelectCharUI::destroy(self : SelectCharUI) -> Unit {
  self.btn_select.destroy()
  for entity in self.entities {
    entity.destroy()
  }
}

///|
async fn add_select_char_ui(mod : CharLookMod) -> SelectCharUI {
  let slots = [{ cid: 1, name: "kkkiio" }]
  SelectCharUI::new(
    SelectCharUIResource::load(),
    slots,
    on_select_character=fn(slot) {
      guard select_char_ui.val is Some(ui) else { return }
      @game_server.send(SelectCharMessage::{
        character_id: ui.characters[slot].cid,
      })
    },
    mod,
  )
}

///|
let select_char_loading_future : Ref[
  @utils.Future[Result[SelectCharUI, Error]]?,
] = Ref::new(None)

///|
pub fn select_char_system(_delta : Double) -> Unit {
  guard @char_look.get_module() is Some(mod) else { return }
  guard game_state.phase is GamePhase::SelectCharacter else { return }

  // If UI is already loaded, update animations
  if select_char_ui.val is Some(ui) {
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
      // if @sprite.sprites.get(entity) is Some(spr) {
      //   @sprite.sprites.set(entity, { ..spr, alpha: alpha_norm })
      // }
      // TODO: modify upstream selene to support alpha
      ignore(entity)
      ignore(alpha_norm)
    }
    return
  }

  // If not loading yet, start background task
  guard select_char_loading_future.val is Some(fut) else {
    select_char_loading_future.val = Some(
      @io_service.submit_background_task(fn() { add_select_char_ui(mod) }),
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
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "select_char",
    @net.Opcode::SET_FIELD.int_value(),
    fn(json) {
      let set_field_message : SetFieldMessage = @json.from_json(json)
      guard set_field_message is SetField(stats={ map_id, portal_id, .. }, ..) else {
        return
      }
      guard select_char_ui.val is Some(ui) else { return }
      @game_state.game_state.phase = @game_state.GamePhase::GameStart(
        map_id~,
        portal_id~,
        loading_data=None,
      )
      select_char_ui.val = None
      ui.destroy()
    },
  )
}
