///|
struct SelectCharUI {
  characters : Array[(Int, @char_look.CharLook, @ui.NameTag)]
  on_select_character : (Int) -> Unit
  on_new_character : () -> Unit
  mut select_slot : Int?
  resource : SelectCharUIResource
}

///|
pub(all) struct SelectCharUIResource {
  name_tag : @ui.NameTagResource
  bt_select : @ui.MapleButtonResource
  bt_new : @ui.MapleButtonResource
  ani17 : @sprite.Animation
  ani18 : @sprite.Animation
  ani19 : @sprite.Animation
  // frame : @graphics.Animation
  // step2 : @graphics.Animation
}

///|
pub fn SelectCharUIResource::load() -> SelectCharUIResource raise {
  let ani17_res : Json = {
    "0": {
      "__h": 505,
      "__w": 242,
      "a0": 255,
      "a1": 50,
      "delay": 3000,
      "origin": [121, 252],
      "z": 0,
      "__i": "assets/ui/login.img/char_select/light17.png",
    },
    "1": {
      "__h": 505,
      "__w": 242,
      "_inlink": "ani/17/0",
      "a0": 50,
      "a1": 255,
      "delay": 3000,
      "origin": [121, 252],
      "z": 0,
      "__i": "assets/ui/login.img/char_select/light17.png",
    },
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
      "__i": "assets/ui/login.img/char_select/light18.png",
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
      "__i": "assets/ui/login.img/char_select/light18.png",
    },
  }
  let ani19_res : Json = {
    "0": {
      "__h": 355,
      "__w": 312,
      "a0": 200,
      "a1": 80,
      "delay": 2300,
      "origin": [156, 177],
      "z": 0,
      "__i": "assets/ui/login.img/char_select/light19.png",
      "__off": [0, 0],
    },
    "1": {
      "__h": 355,
      "__w": 312,
      "a0": 80,
      "a1": 255,
      "delay": 3300,
      "origin": [156, 177],
      "z": 0,
      "__i": "assets/ui/login.img/char_select/light19.png",
      "__off": [312, 0],
    },
    "2": {
      "__h": 355,
      "__w": 312,
      "_inlink": "ani/19/1",
      "a0": 255,
      "a1": 200,
      "delay": 1000,
      "origin": [156, 177],
      "z": 0,
      "__i": "assets/ui/login.img/char_select/light19.png",
      "__off": [312, 0],
    },
  }
  // let frame = login_loader.load_res(["Common", "frame"])
  // let step2 = login_loader.load_res(["Common", "step", "2"])
  let name_tag_res : Json = {
    "0": {
      "0": {
        "__h": 23,
        "__w": 6,
        "origin": [0, 0],
        "z": 0,
        "__i": "assets/ui/login.img/char_select/name_tag.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 23,
        "__w": 1,
        "origin": [0, 0],
        "z": 0,
        "__i": "assets/ui/login.img/char_select/name_tag.png",
        "__off": [12, 0],
      },
      "2": {
        "__h": 23,
        "__w": 6,
        "origin": [0, 0],
        "z": 0,
        "__i": "assets/ui/login.img/char_select/name_tag.png",
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
        "__i": "assets/ui/login.img/char_select/name_tag.png",
        "__off": [0, 0],
      },
      "1": {
        "__h": 23,
        "__w": 1,
        "origin": [0, 0],
        "z": 0,
        "__i": "assets/ui/login.img/char_select/name_tag.png",
        "__off": [13, 0],
      },
      "2": {
        "__h": 23,
        "__w": 6,
        // "_inlink": "CharSelect/nameTag/0/2",
        "origin": [0, 0],
        "z": 0,
        "__i": "assets/ui/login.img/char_select/name_tag.png",
        "__off": [6, 0],
      },
    },
  }
  let bt_select_res : Json = {
    "disabled": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28154",
      },
    },
    "keyFocused": {
      "0": {
        "__h": 25,
        "__w": 35,
        "delay": "50",
        "origin": [-132, 14],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
      "1": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtSelect/keyFocused/0",
        "delay": "50",
        "origin": [-132, 13],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
      "2": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtSelect/keyFocused/0",
        "delay": "50",
        "origin": [-132, 12],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
      "3": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtSelect/keyFocused/0",
        "delay": "50",
        "origin": [-132, 11],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
      "4": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtSelect/keyFocused/0",
        "delay": "50",
        "origin": [-132, 12],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
      "5": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtSelect/keyFocused/0",
        "delay": "50",
        "origin": [-132, 13],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28155",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28152",
      },
    },
    "normal": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28151",
      },
    },
    "pressed": {
      "0": {
        "__h": 52,
        "__w": 140,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtSelect#28153",
      },
    },
  }
  let bt_new_res : Json = {
    "disabled": {
      "0": {
        "__h": 37,
        "__w": 110,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28164",
      },
    },
    "keyFocused": {
      "0": {
        "__h": 25,
        "__w": 35,
        "origin": [-85, 17],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
      "1": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtNew/keyFocused/0",
        "delay": "50",
        "origin": [-85, 16],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
      "2": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtNew/keyFocused/0",
        "delay": "50",
        "origin": [-85, 15],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
      "3": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtNew/keyFocused/0",
        "delay": "50",
        "origin": [-85, 14],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
      "4": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtNew/keyFocused/0",
        "delay": "50",
        "origin": [-85, 15],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
      "5": {
        "__h": 25,
        "__w": 35,
        "_inlink": "CharSelect/BtNew/keyFocused/0",
        "delay": "50",
        "origin": [-85, 16],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28165",
      },
    },
    "mouseOver": {
      "0": {
        "__h": 37,
        "__w": 110,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28162",
      },
    },
    "normal": {
      "0": {
        "__h": 37,
        "__w": 110,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28161",
      },
    },
    "pressed": {
      "0": {
        "__h": 37,
        "__w": 110,
        "origin": [0, 0],
        "z": 0,
        "__i": "spritesheets/UI/Login.img/CharSelect/BtNew#28163",
      },
    },
  }
  let ani17 : @graphics.NxAnimation = @json.from_json(ani17_res)
  let ani18 : @graphics.NxAnimation = @json.from_json(ani18_res)
  let ani19 : @graphics.NxAnimation = @json.from_json(ani19_res)
  {
    name_tag: @json.from_json(name_tag_res),
    bt_select: @json.from_json(bt_select_res),
    bt_new: @json.from_json(bt_new_res),
    ani17: ani17.inner(),
    ani18: ani18.inner(),
    ani19: ani19.inner(),
    // frame: @graphics.Animation::from_resource_ex(frame),
    // step2: @graphics.Animation::from_resource_ex(step2),
  }
}

///|
pub fn SelectCharUI::new(
  resources : SelectCharUIResource,
  characters : Array[(Int, @char_look.CharLook, String)],
  on_select_character? : (Int) -> Unit = fn(_i) {  },
  on_new_character? : () -> Unit = fn() {  },
) -> SelectCharUI {
  let entity = @system.Entity::new()
  @position.positions.set(entity, @position.Position(@selene_math.Vec2D(0, 0)))
  @selene_ui.uis.set(entity, @selene_ui.Ui::new())
  // ui_model.dimension = @struct.Point::new(800, 600)

  let back13 = @sprite.Animation::single_frame(
    "assets/ui/login.img/char_select/back13.png",
    @selene_math.Vec2D(800, 600),
    //   "origin": [392, 297],
  )
  for
    t in [
      (back13, @selene_math.Vec2D(0, 0)),
      (resources.ani17, @selene_math.Vec2D(151, 283)),
      (resources.ani18, @selene_math.Vec2D(365, 252)),
      (resources.ani19, @selene_math.Vec2D(191, 208)),
      // @graphics.Sprite::new(
      //   resources.frame,
      //   @graphics.DrawArgument::new(pos=@struct.Point::new(400, 300)),
      // ),
      // @graphics.Sprite::new(
      //   resources.step2,
      //   @graphics.DrawArgument::new(pos=@struct.Point::new(40, 0)),
      // ),
    ] {
    let (s, pos) = t
    let entity = @system.Entity::new()
    @position.positions.set(entity, @position.Position(pos))
    @selene_ui.uis.set(entity, @selene_ui.Ui::new())
    @sprite.sprites.set(
      entity,
      @sprite.Sprite::from_animation(s, @selene_ui.UI_ZINDEX),
    )
  }
  {
    select_slot: None,
    on_select_character,
    on_new_character,
    characters: characters.map(fn(it) {
      let (cid, char_look, name) = it
      (
        cid,
        char_look,
        @ui.NameTag::new(@graphics.FontId::A13M, name, resources.name_tag),
      )
    }),
    resource: resources,
  }
}

///|
pub impl @ui.Widget for SelectCharUI with render(self) -> @ui.RenderSpec {
  let resources = self.resource
  let render_elements = []
  render_elements.push(
    (@ui.MapleButton::new(resources.bt_select, pos=@struct.Point::new(601, 393))
    |> @ui.Button::new(on_click=fn() {
      guard self.select_slot is Some(slot) else { return None }
      let cid = self.characters[slot].0
      (self.on_select_character)(cid)
      None
    })).as_interactable(),
  )
  // Point<int16_t> character_new_pos = Point<int16_t>(200, 495);
  // buttons_[Buttons::CHARACTER_NEW] =
  //     std::make_unique<MapleButton>(CharSelect["BtNew"], character_new_pos);
  render_elements.push(
    @ui.MapleButton::new(resources.bt_new, pos=@struct.Point::new(200, 495))
    |> @ui.Button::new(on_click=fn() {
      (self.on_new_character)()
      None
    })
    |> @ui.Button::as_interactable,
  )
  for i in 0..<@cmp.minimum(self.characters.length(), PAGE_SIZE) {
    render_elements.push(
      @ui.AreaButton::new(
        get_character_slot_pos(i, 105, 144),
        @struct.Point::new(50, 90),
      )
      |> @ui.Button::new(on_click=fn() {
        self.select_slot = Some(i)
        // (self.hooks.on_state_changed)()
        None
      })
      |> @ui.Button::as_interactable,
    )
    let (_, char_look, name_tag) = self.characters[i]
    char_look.set_stance(
      if Some(i) == self.select_slot {
        @types.StanceId::WALK1
      } else {
        @types.StanceId::STAND1
      },
    )
    char_look.set_direction(true)
    render_elements.push(
      { char_look, pos: get_character_slot_pos(i, 135, 234) }
      |> @ui.RenderElement::Static,
    )
    name_tag.set_selected(Some(i) == self.select_slot)
    render_elements.push(
      @ui.StaticUI::new(name_tag, pos=get_character_slot_pos(i, 135, 234))
      |> @ui.RenderElement::Static,
    )
  }
  { render_elements, }
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
  self.char_look.update(@config.step_time_ms) |> ignore
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
pub fn select_char_system(_backend : &@system.Backend) -> Unit {
  let ui = match select_char_ui.val {
    Some(ui) => ui
    None => {
      let n = SelectCharUI::new((try? SelectCharUIResource::load()).unwrap(), [])
      select_char_ui.val = Some(n)
      n
    }
  }
  ignore(ui)
}
