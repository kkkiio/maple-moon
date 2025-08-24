///|
struct SelectCharUI {
  characters : Array[(Int, @char_look.CharLook, @ui.NameTag)]
  on_select_character : (Int) -> Unit
  on_new_character : () -> Unit
  mut select_slot : Int?
  resource : SelectCharUIResource
  hooks : @ui.Hooks
}

///|
pub(all) struct SelectCharUIResource {
  name_tag : @ui.NameTagResource
  bt_select : @ui.MapleButtonResource
  bt_new : @ui.MapleButtonResource
  back13 : @graphics.Animation
  ani17 : @graphics.Animation
  ani18 : @graphics.Animation
  ani19 : @graphics.Animation
  frame : @graphics.Animation
  step2 : @graphics.Animation
} derive(Default)

///|
pub async fn SelectCharUIResource::load(
  login_loader : @resource.SyncLoader
) -> SelectCharUIResource raise {
  let char_select_src = login_loader.load_res(["CharSelect"])
  let map001_loader = get_map001_loader()
  let back13 = map001_loader.load_res_async(["Back", "login.img", "back", "13"])
  let ani17 = map001_loader.load_res_async(["Back", "login.img", "ani", "17"])
  let ani18 = map001_loader.load_res_async(["Back", "login.img", "ani", "18"])
  let ani19 = map001_loader.load_res_async(["Back", "login.img", "ani", "19"])
  let frame = login_loader.load_res(["Common", "frame"])
  let step2 = login_loader.load_res(["Common", "step", "2"])
  {
    name_tag: @ui.NameTagResource::from_resource(char_select_src["nameTag"]),
    bt_select: @ui.MapleButtonResource::from_resource(
      char_select_src["BtSelect"],
    ),
    bt_new: @ui.MapleButtonResource::from_resource(char_select_src["BtNew"]),
    back13: @graphics.Animation::from_resource_ex(back13),
    ani17: @graphics.Animation::from_resource_ex(ani17),
    ani18: @graphics.Animation::from_resource_ex(ani18),
    ani19: @graphics.Animation::from_resource_ex(ani19),
    frame: @graphics.Animation::from_resource_ex(frame),
    step2: @graphics.Animation::from_resource_ex(step2),
  }
}

///|
pub fn SelectCharUI::new(
  resource : SelectCharUIResource,
  characters : Array[(Int, @char_look.CharLook, String)],
  hooks : @ui.Hooks,
  on_select_character~ : (Int) -> Unit = fn(_i) {  },
  on_new_character~ : () -> Unit = fn() {  }
) -> SelectCharUI {
  let ui_model = hooks.ui_model
  ui_model.position = @struct.Point::new(0, 0)
  ui_model.dimension = @struct.Point::new(800, 600)
  {
    select_slot: None,
    on_select_character,
    on_new_character,
    characters: characters.map(fn(it) {
      let (cid, char_look, name) = it
      (
        cid,
        char_look,
        @ui.NameTag::new(@graphics.FontId::A13M, name, resource.name_tag),
      )
    }),
    resource,
    hooks,
  }
}

///|
pub impl @ui.Widget for SelectCharUI with render(self) -> @ui.RenderSpec {
  let resources = self.resource
  let render_elements = []
  render_elements.push_iter(
    [
      @graphics.Sprite::new(
        resources.back13,
        @graphics.DrawArgument::new(pos=@struct.Point::new(392, 297)),
      ),
      @graphics.Sprite::new(
        resources.ani17,
        @graphics.DrawArgument::new(pos=@struct.Point::new(151, 283)),
      ),
      @graphics.Sprite::new(
        resources.ani18,
        @graphics.DrawArgument::new(pos=@struct.Point::new(365, 252)),
      ),
      @graphics.Sprite::new(
        resources.ani19,
        @graphics.DrawArgument::new(pos=@struct.Point::new(191, 208)),
      ),
      @graphics.Sprite::new(
        resources.frame,
        @graphics.DrawArgument::new(pos=@struct.Point::new(400, 300)),
      ),
      @graphics.Sprite::new(
        resources.step2,
        @graphics.DrawArgument::new(pos=@struct.Point::new(40, 0)),
      ),
    ]
    .iter()
    .map(fn(it) { @ui.SpriteUI(it) |> @ui.RenderElement::Static }),
  )
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
  for i in 0..<@math.minimum(self.characters.length(), PAGE_SIZE) {
    render_elements.push(
      @ui.AreaButton::new(
        get_character_slot_pos(i, 105, 144),
        @struct.Point::new(50, 90),
      )
      |> @ui.Button::new(on_click=fn() {
        self.select_slot = Some(i)
        (self.hooks.on_state_changed)()
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
  y_adj : Int
) -> @struct.Point[Int] {
  let x = 125 * (index % 4)
  let y = 200 * (index > 3).to_int()
  return @struct.Point::new(x + x_adj, y + y_adj)
}

///|
const PAGE_SIZE = 8
