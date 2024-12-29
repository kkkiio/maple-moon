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
    new_create_char_packet(
      cname, 1, cface, chair, chairc, cskin, ctop, cbot, cshoe, cwep, female,
    ).dispatch()
  } else {
    @log.warn({ "name": cname }, "Name already in use")
  }
}

///| Reserve a name for the character to be created.
fn new_name_char_packet(name : String) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::NAME_CHAR)..write_string(name)
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

///|
struct SelectCharUI {
  model : @ui.UIModel
  characters : Array[(Int, @char_look.CharLook, @ui.NameTag)]
  on_character_selected : (Int) -> Unit
  mut select_slot : Int?
  resource : SelectCharUIResource
  hooks : @ui.Hooks
}

///|
pub(all) struct SelectCharUIResource {
  name_tag : @ui.NameTagResource
  bt_select : @ui.MapleButtonResource
  back13 : @graphics.Animation
  ani17 : @graphics.Animation
  ani18 : @graphics.Animation
  ani19 : @graphics.Animation
  frame : @graphics.Animation
  step2 : @graphics.Animation
}

///|
pub fn SelectCharUIResource::load() -> @utils.Future[SelectCharUIResource] {
  let char_select_src = @ui.common_ui_loader().load_res([
    "Login.img", "CharSelect",
  ])
  let back13_f = get_map001_loader().load_res([
    "Back", "login.img", "back", "13",
  ])
  let ani17_f = get_map001_loader().load_res(["Back", "login.img", "ani", "17"])
  let ani18_f = get_map001_loader().load_res(["Back", "login.img", "ani", "18"])
  let ani19_f = get_map001_loader().load_res(["Back", "login.img", "ani", "19"])
  let frame = @ui.common_ui_loader().load_res(["Login.img", "Common", "frame"])
  let step2 = @ui.common_ui_loader().load_res([
    "Login.img", "Common", "step", "2",
  ])
  back13_f
  .combine(ani17_f)
  .combine(ani18_f)
  .combine(ani19_f)
  .map(fn(it) {
    let (((back13, ani17), ani18), ani19) = it
    {
      name_tag: @ui.NameTagResource::from_resource(char_select_src["nameTag"]),
      bt_select: @ui.MapleButtonResource::from_resource(
        char_select_src["BtSelect"],
      ),
      back13: @graphics.Animation::from_resource_ex?(back13).unwrap(),
      ani17: @graphics.Animation::from_resource_ex?(ani17).unwrap(),
      ani18: @graphics.Animation::from_resource_ex?(ani18).unwrap(),
      ani19: @graphics.Animation::from_resource_ex?(ani19).unwrap(),
      frame: @graphics.Animation::from_resource_ex?(frame).unwrap(),
      step2: @graphics.Animation::from_resource_ex?(step2).unwrap(),
    }
  })
}

///|
pub fn SelectCharUI::new(
  resource : SelectCharUIResource,
  characters : Array[(Int, @char_look.CharLook, String)],
  on_character_selected~ : (Int) -> Unit = fn(_i) {  },
  hooks : @ui.Hooks
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
    hooks,
  }
}

///|
pub impl @ui.UIElement for SelectCharUI with render(self) -> @ui.RenderSpec {
  let resources = self.resource
  let render_units : Array[&@ui.RenderUnit] = []
  render_units.push_iter(
    [
      @graphics.Sprite::new(
        resources.back13,
        @graphics.DrawArgument::new(position=@struct.Point::new(392, 297)),
      ),
      @graphics.Sprite::new(
        resources.ani17,
        @graphics.DrawArgument::new(position=@struct.Point::new(151, 283)),
      ),
      @graphics.Sprite::new(
        resources.ani18,
        @graphics.DrawArgument::new(position=@struct.Point::new(365, 252)),
      ),
      @graphics.Sprite::new(
        resources.ani19,
        @graphics.DrawArgument::new(position=@struct.Point::new(191, 208)),
      ),
      @graphics.Sprite::new(
        resources.frame,
        @graphics.DrawArgument::new(position=@struct.Point::new(400, 300)),
      ),
      @graphics.Sprite::new(
        resources.step2,
        @graphics.DrawArgument::new(position=@struct.Point::new(40, 0)),
      ),
    ]
    .iter()
    .map(fn(it) { @ui.SpriteUI(it) }),
  )
  render_units.push(
    @ui.MapleButton::new(resources.bt_select, pos=@struct.Point::new(601, 393))
    |> @ui.Button::new(on_click=fn() {
      guard let Some(slot) = self.select_slot else { None => return None }
      let cid = self.characters[slot].0
      (self.on_character_selected)(cid)
      None
    }),
  )
  for i in 0..<@math.minimum(self.characters.length(), PAGE_SIZE) {
    render_units.push(
      @ui.AreaButton::new(
        get_character_slot_pos(i, 105, 144),
        @struct.Point::new(50, 90),
      )
      |> @ui.Button::new(on_click=fn() {
        self.select_slot = Some(i)
        (self.hooks.on_state_changed)()
        None
      }),
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
    name_tag.set_selected(Some(i) == self.select_slot)
    render_units.push({
      name_tag,
      char_look,
      pos: get_character_slot_pos(i, 135, 234),
    })
  }
  { render_units, }
}

///|
struct CharDrawable {
  char_look : @char_look.CharLook
  name_tag : @ui.NameTag
  pos : @struct.Point[Int]
}

///|
impl @ui.Drawable for CharDrawable with draw(self, _pos) -> Unit {
  self.char_look.draw(@graphics.DrawArgument::new(position=self.pos), 0)
  self.name_tag.draw(self.pos)
}

///|
impl @ui.RenderUnit for CharDrawable with update(self) -> Unit {
  self.char_look.update(@constants.step_time_ms) |> ignore
}

///|
impl @ui.RenderUnit for CharDrawable with get_interactive_area(self) { None }

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
