///|
let test_name = "kkkiio1"

///|
struct ExplorerCreator {
  skins : @utils.BoolPair[Array[Int]]
  haircolors : @utils.BoolPair[Array[Int]]
  faces : @utils.BoolPair[Array[Int]]
  hairs : @utils.BoolPair[Array[Int]]
  tops : @utils.BoolPair[Array[Int]]
  bots : @utils.BoolPair[Array[Int]]
  shoes : @utils.BoolPair[Array[Int]]
  weapons : @utils.BoolPair[Array[Int]]
}

///|
fn ExplorerCreator::new(src : @resource.NxNode) -> ExplorerCreator {
  let faces = @utils.BoolPair::new([], [])
  let hairs = @utils.BoolPair::new([], [])
  let haircolors = @utils.BoolPair::new([], [])
  let skins = @utils.BoolPair::new([], [])
  let tops = @utils.BoolPair::new([], [])
  let bots = @utils.BoolPair::new([], [])
  let shoes = @utils.BoolPair::new([], [])
  let weapons = @utils.BoolPair::new([], [])
  let mkinfo = src
  for i = 0; i < 2; i = i + 1 {
    let (f, char) = if i == 0 {
      (true, mkinfo["CharFemale"])
    } else {
      (false, mkinfo["CharMale"])
    }
    for name, node in char {
      let num = @strconv.parse_int?(name).unwrap()
      for _, idnode in node {
        let value = idnode.get_int?().unwrap()
        match num {
          0 => faces[f].push(value)
          1 => hairs[f].push(value)
          2 => haircolors[f].push(value)
          3 => skins[f].push(value)
          4 => tops[f].push(value)
          5 => bots[f].push(value)
          6 => shoes[f].push(value)
          7 => weapons[f].push(value)
          _ => ()
        }
      }
    }
  }
  { faces, hairs, haircolors, skins, tops, bots, shoes, weapons }
}

///|
fn send_naming_result(
  self : ExplorerCreator,
  cname : String,
  nameused : Bool
) -> Unit {
  let female = false
  if not(nameused) {
    let cface = self.faces[female][0]
    let chair = self.hairs[female][0]
    let chairc = self.haircolors[female][0]
    let cskin = self.skins[female][0]
    let ctop = self.tops[female][0]
    let cbot = self.bots[female][0]
    let cshoe = self.shoes[female][0]
    let cwep = self.weapons[female][0]
    fn_create_char(
      cname, 1, cface, chair, chairc, cskin, ctop, cbot, cshoe, cwep, female,
    )
  } else {
    @log.warn({ "name": cname }, "Name already in use")
  }
}

///| Reserve a name for the character to be created.
fn new_name_char_packet(name : String) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NAME_CHAR)..write_string(name)
}

///|
fn fn_create_char(
  name : String,
  job : Int,
  face : Int,
  hair : Int,
  hairc : Int,
  skin : Int,
  top : Int,
  bot : Int,
  shoes : Int,
  weapon : Int,
  female : Bool
) -> Unit {
  new_create_char_packet(
    name, job, face, hair, hairc, skin, top, bot, shoes, weapon, female,
  ).dispatch()
}

///| Requests creation of a character with the specified stats.
fn new_create_char_packet(
  name : String,
  job : Int,
  face : Int,
  hair : Int,
  hairc : Int,
  skin : Int,
  top : Int,
  bot : Int,
  shoes : Int,
  weapon : Int,
  female : Bool
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CREATE_CHAR)
  ..write_string(name)
  ..write_int(job)
  ..write_int(face)
  ..write_int(hair)
  ..write_int(hairc)
  ..write_int(skin)
  ..write_int(top)
  ..write_int(bot)
  ..write_int(shoes)
  ..write_int(weapon)
  ..write_byte(female.to_int().to_byte())
}

///| Tell the server which character was picked.
fn new_select_char_packet(character_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SELECT_CHAR)
  ..write_int(character_id)
  ..write_hardware_info()
}

///|
struct SelectCharUI {
  logic_state : LogicState
  resources : Resources
  mut runtime_state : RuntimeState?
}

///|
struct LogicState {
  model : @ui.UIModel
  mut attributes : Attributes
  mut select_slot : Int?
}

///|
struct Attributes {
  char_look_module : @char_look.Module
  characters : Array[@character.CharEntry]
  set_selected_cid : (Int) -> Unit
}

///|
struct RuntimeState {
  model : @ui.UIModel
  buttons : Array[@ui.Button]
  char_looks : Array[@char_look.CharLook]
  name_tags : Array[@ui.NameTag]
}

///|
struct Resources {
  name_tag : @resource.NxNode
  bt_select : @resource.NxNode
}

///|
fn SelectCharUI::new(attributes : Attributes) -> SelectCharUI {
  let logic_state = {
    attributes,
    select_slot: None,
    model: @ui.UIModel::new(
      @struct.Point::new(0, 0),
      @struct.Point::new(800, 600),
    ),
  }
  let char_select = @ui.common_ui_loader().load_res(["Login.img", "CharSelect"])
  let name_tag = char_select["nameTag"]
  let bt_select = char_select["BtSelect"]
  let resources = { name_tag, bt_select }
  { logic_state, resources, runtime_state: None }
}

///|
pub fn set_attributes(self : SelectCharUI, attributes : Attributes) -> Unit {
  self.logic_state.attributes = attributes
  self.runtime_state = None
}

///|
fn render(self : LogicState, resources : Resources) -> RuntimeState {
  let buttons = [
    @ui.MapleButton::from_resource(
      resources.bt_select,
      pos=@struct.Point::new(601, 393),
    )
    |> @ui.Button::new(on_click=fn() {
      guard let Some(slot) = self.select_slot else {
        None => return @ui.ButtonState::IDENTITY
      }
      let cid = self.attributes.characters[slot].id
      (self.attributes.set_selected_cid)(cid)
      new_select_char_packet(cid).dispatch()
      @ui.ButtonState::IDENTITY
    }),
  ]
  for i in 0..<PAGE_SIZE {
    buttons.push(
      @ui.AreaButton::new(
        get_character_slot_pos(i, 105, 144),
        @struct.Point::new(50, 90),
      )
      |> @ui.Button::new(on_click=fn() {
        self.select_slot = Some(i)
        @ui.ButtonState::IDENTITY
      }),
    )
  }
  // Create runtime state for current frame
  let char_looks = self.attributes.characters.map(fn(c) {
    self.attributes.char_look_module.new_char_look(c.look)
  })
  let name_tags = self.attributes.characters.map(fn(c) {
    @ui.NameTag::new(resources.name_tag, @graphics.FontId::A13M, c.stats.name)
  })
  { char_looks, name_tags, buttons, model: self.model }
}

///|
fn draw(self : RuntimeState, alpha : Double) -> Unit {
  // Draw characters
  for i in 0..<self.char_looks.length() {
    let char_pos = get_character_slot_pos(i, 135, 234)
    self.char_looks[i].draw(char_pos |> @graphics.DrawArgument::new, alpha)
    self.name_tags[i].draw(char_pos)
  }
  for button in self.buttons {
    button.object.draw(self.model.position)
  }
}

///|
fn use_runtime_state(self : SelectCharUI) -> RuntimeState {
  match self.runtime_state {
    Some(rs) => rs
    None => {
      let render_state = render(self.logic_state, self.resources)
      self.runtime_state = Some(render_state)
      render_state
    }
  }
}

///|
impl @ui.UIElement for SelectCharUI with render(self) -> @ui.RuntimeState {
  let s = self.logic_state.render(self.resources)
  { buttons: s.buttons, draw_fn: fn(alpha) { s.draw(alpha) }, sprites: [] }
}

///|
fn get_character_slot_pos(
  index : Int,
  x_adj : Int,
  y_adj : Int
) -> @struct.Point[Int] {
  let x = 125 * (index % 4)
  let y = 200 * (index > 3).to_int()
  return @struct.Point::new(x + x_adj, y + y_adj)
}

///|
const PAGE_SIZE = 8

///|
pub fn remove_cursor(self : SelectCharUI) -> Unit {
  // TODO: implement
}

///|
pub fn send_key(
  self : SelectCharUI,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

///|
pub fn get_ui_model(self : SelectCharUI) -> @ui.UIModel {
  self.logic_state.model
}
