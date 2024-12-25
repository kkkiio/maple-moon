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
  model : @ui.UIModel
  characters : Array[(Int, @char_look.CharLook, @ui.NameTag)]
  on_character_selected : (Int) -> Unit
  mut select_slot : Int?
  resource : SelectCharUIResource
}

///|
pub(all) struct SelectCharUIResource {
  name_tag : @ui.NameTagResource
  bt_select : @ui.MapleButtonResource
}

///|
pub fn SelectCharUIResource::from_resource(
  src : @resource.NxNode
) -> SelectCharUIResource {
  {
    name_tag: @ui.NameTagResource::from_resource(src["nameTag"]),
    bt_select: @ui.MapleButtonResource::from_resource(src["BtSelect"]),
  }
}

///|
pub fn SelectCharUI::new(
  resource : SelectCharUIResource,
  characters : Array[(Int, @char_look.CharLook, String)],
  on_character_selected~ : (Int) -> Unit = fn(_i) {  }
) -> SelectCharUI {
  {
    select_slot: None,
    on_character_selected,
    characters: characters.map(fn(it) {
      let (cid, char_look, name) = it
      (
        cid,
        char_look,
        @ui.NameTag::new(@graphics.FontId::A13M, name, resource.name_tag),
      )
    }),
    model: @ui.UIModel::new(
      @struct.Point::new(0, 0),
      @struct.Point::new(800, 600),
    ),
    resource,
  }
}

///|
pub impl @ui.UIElement for SelectCharUI with render(self) -> @ui.RenderSpec {
  let resources = self.resource
  let buttons = [
    @ui.MapleButton::new(resources.bt_select, pos=@struct.Point::new(601, 393))
    |> @ui.Button::new(on_click=fn() {
      guard let Some(slot) = self.select_slot else {
        None => return @ui.ButtonState::IDENTITY
      }
      let cid = self.characters[slot].0
      (self.on_character_selected)(cid)
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
  let char_looks = self.characters.map(fn(c) { c.1 })
  let name_tags = self.characters.map(fn(c) { c.2 })
  {
    buttons,
    sprites: [],
    drawables: char_looks.mapi(fn(i, c) {
      {
        char_look: c,
        name_tag: name_tags[i],
        pos: get_character_slot_pos(i, 135, 234),
      }
    }),
  }
}

///|
struct CharDrawable {
  char_look : @char_look.CharLook
  name_tag : @ui.NameTag
  pos : @struct.Point[Int]
}

///|
impl @ui.DrawableUI for CharDrawable with draw(self, _pos, alpha) -> Unit {
  self.char_look.draw(@graphics.DrawArgument::new(self.pos), alpha)
  self.name_tag.draw(self.pos)
}

///|
pub impl ToJson for CharDrawable with to_json(self) -> Json {
  {
    "char_look": self.char_look.to_json(),
    "name_tag": self.name_tag.to_json(),
    "pos": self.pos.to_json(),
  }
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
  self.model
}
