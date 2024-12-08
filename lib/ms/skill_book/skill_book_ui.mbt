///|
let skill_offset : @struct.Point[Int] = @struct.Point::new(11, 93)

///|
let skill_meta_offset : @struct.Point[Int] = @struct.Point::new(2, 2)

///|
let line_offset : @struct.Point[Int] = @struct.Point::new(0, 37)

///|
let rows : Int = 12

///|
let row_height : Int = 40

///|
let row_width : Int = 143

///|
struct SkillDisplayMeta {
  id : @skill.SkillId
  icon : StatefulIcon
  name_text : @graphics.Text
  level_text : @graphics.Text
}

///|
struct LogicState {
  mut attrs : Attributes
  model : @ui.UIModel
  btn_close : @ui.MapleButton
  btn_hyper : @ui.MapleButton
  btn_guild_skill : @ui.MapleButton
  btn_ride : @ui.MapleButton
  sp_up_btns : Array[@ui.MapleButton]
  mut tab : Int
}

///|
struct Resources {
  sprites : Array[@graphics.Sprite]
  tab_btn_disabled_res : @resource.NxNode
  tab_btn_enabled_res : @resource.NxNode
  line : @graphics.Texture
  skille : @graphics.Texture
  skilld : @graphics.Texture
  skillb : @graphics.Texture
}

///|
struct RenderState {
  model : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  buttons : Array[@ui.Button]
  book_icon : @graphics.Texture
  book_text : @graphics.Text
  sp_label : @graphics.Text
  skills : Array[SkillDrawState]
}

///|
struct SkillDrawState {
  enabled : Bool
  icon : StatefulIcon
  name_text : @graphics.Text
  level_text : @graphics.Text
}

///|
fn draw(self : SkillDrawState, args : @graphics.DrawArgument) -> Unit {
  self.icon.draw(args.get_pos())
  self.name_text.draw(args.get_pos() + @struct.Point::new(38, -5))
  self.level_text.draw(args.get_pos() + @struct.Point::new(38, 13))
}

///|
struct SkillBookUI {
  logic_state : LogicState
  resources : Resources
  mut render_state : RenderState?
}

///|
pub(all) struct Attributes {
  skillbook : @character.SkillBook
  job : @job.Job
  level : Int
  sp : Int
}

///|
fn SkillBookUI::new(
  attrs : Attributes,
  skill : @resource.NxNode
) -> SkillBookUI {
  let main = skill["main"]
  let ui_backgrnd = main["backgrnd"]
  let bg_dimensions = @graphics.Texture::get_dimensions(
    ui_backgrnd |> @graphics.Texture::from_resource,
  )
  let skilld = main["skill0"] |> @graphics.Texture::from_resource
  let skille = main["skill1"] |> @graphics.Texture::from_resource
  let skillb = main["skillBlank"] |> @graphics.Texture::from_resource
  let line = main["line"] |> @graphics.Texture::from_resource
  let sprites = []
  sprites.push(
    @graphics.Sprite::from_resource(
      ui_backgrnd,
      state_args=@struct.Point::new(1, 0) |> @graphics.DrawArgument::from_point,
    ),
  )
  sprites.push(@graphics.Sprite::from_resource(main["backgrnd2"]))
  sprites.push(@graphics.Sprite::from_resource(main["backgrnd3"]))
  let close = @ui.common_ui_loader().load_res(["Basic.img", "BtClose3"])
  let btn_close = @ui.MapleButton::from_resource(
    close,
    pos=@struct.Point::new(bg_dimensions.x - 23, 6),
  )
  let tab_res = main["Tab"]
  let tab_btn_enabled_res = tab_res["enabled"]
  let tab_btn_disabled_res = tab_res["disabled"]
  let sp_up_btns = []
  let mut y_adj = 0
  for i in 0..<12 {
    let mut x_adj = 0
    if i % 2 != 0 {
      x_adj = row_width
    }
    let spup_position = skill_offset +
      @struct.Point::new(124 + x_adj, 20 + y_adj)
    sp_up_btns.push(
      @ui.MapleButton::from_resource(main["BtSpUp"], pos=spup_position),
    )
    if i % 2 != 0 {
      y_adj += row_height
    }
  }

  // TODO: slider
  let dimension = bg_dimensions
  let model = @ui.UIModel::new(@struct.Point::default(), dimension)
  let btn_hyper = @ui.MapleButton::from_resource(main["BtHyper"])
  let btn_guild_skill = @ui.MapleButton::from_resource(main["BtGuildSkill"])
  let btn_ride = @ui.MapleButton::from_resource(main["BtRide"])
  let render_state = {
    attrs,
    model,
    btn_close,
    btn_hyper,
    btn_guild_skill,
    btn_ride,
    sp_up_btns,
    tab: 0,
  }
  {
    logic_state: render_state,
    resources: {
      sprites,
      line,
      skille,
      skilld,
      skillb,
      tab_btn_disabled_res,
      tab_btn_enabled_res,
    },
    render_state: None,
  }
}

///|
fn render(
  self : LogicState,
  resources : Resources,
  on_state_changed : () -> Unit
) -> RenderState {
  let buttons = []
  buttons.push(self.btn_hyper |> @ui.Button::new)
  buttons.push(self.btn_guild_skill |> @ui.Button::new)
  buttons.push(self.btn_ride |> @ui.Button::new)
  let job = self.attrs.job
  let skillbook = self.attrs.skillbook
  let curr_job_level = job.get_level()
  for i, _ in @job.get_levels(upto=curr_job_level) |> enumerate {
    let tab_btn_disabled_tex = resources.tab_btn_disabled_res[i.to_string()]
      |> @graphics.Texture::from_resource
    let tab_btn_enabled_tex = resources.tab_btn_enabled_res[i.to_string()]
      |> @graphics.Texture::from_resource
    buttons.push(
      @ui.TwoSpriteButton::new(
        tab_btn_disabled_tex,
        tab_btn_enabled_tex,
        state=if i == self.tab {
          @ui.ButtonState::PRESSED
        } else {
          @ui.ButtonState::NORMAL
        },
      )
      |> @ui.Button::new(
        on_click=fn() {
          self.tab = i
          on_state_changed()
          @ui.ButtonState::PRESSED
        },
      ),
    )
  }
  let selected_level = joblevel_by_tab(self.tab)
  let skills = []
  let subid = job.get_subjob(selected_level)
  let job_data = @job.JobData::get(subid)
  for skill_id in job_data.skills {
    let level = skillbook.get_level(skill_id)
    let masterlevel = skillbook.get_masterlevel(skill_id)
    let data = @skill.SkillData::get?(skill_id).unwrap() // TODO: handle error
    let invisible = data.invisible
    if invisible && masterlevel == 0 {
      continue
    }
    let ntx = data.icons[0]
    let dtx = data.icons[1]
    let motx = data.icons[2]
    let icon = StatefulIcon::new(
      // SkillIcon::new(id), // TODO: implement
      ntx, dtx, motx,
    )
    let mut namestr = data.name
    let name_text = @graphics.Text::new(
      text=namestr,
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    )
    let level_text = @graphics.Text::new(
      text=level.to_string(),
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    )
    let max_name_width = 97
    let mut overhang = 3
    while name_text.width() > max_name_width {
      namestr = namestr.substring(end=namestr.length() - overhang) + ".."
      overhang += 1
      name_text.change_text(namestr)
    }
    skills.push(
      {
        name_text,
        level_text,
        icon,
        id: @skill.SkillId::from_int?(skill_id).unwrap(), // TODO: handle error
      },
    )
  }
  let subid = job.get_subjob(selected_level)
  let data = @job.JobData::get(subid)
  let book_icon = data.icon
  let book_text = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    max_width=150,
    text=data.name,
  )
  let beginner_sp = @math.minimum(self.attrs.level - 1, 6) -
    skills
    .iter()
    .filter(fn(skill) { beginner_skills.contains(skill.id) })
    .count()
  let sp = match self.attrs.job.get_level() {
    @job.Level::BEGINNER => beginner_sp
    _ => self.attrs.sp
  }
  let sp_label = @graphics.Text::new(
    text=sp.to_string(),
    @graphics.FontId::A12M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  let model = self.model
  for i, btn in self.sp_up_btns {
    btn.get_button_base().set_active(i < skills.length())
    if i < skills.length() {
      let skill_id = skills[i].id
      let canraise = is_upgradable?(
        self.attrs.skillbook,
        skill_id.int_value(),
        self.tab,
        beginner_sp,
        self.attrs.sp,
      ).unwrap() // TODO: handle error
      btn
      .get_button_base()
      .set_state(
        if canraise {
          @ui.ButtonState::NORMAL
        } else {
          @ui.ButtonState::DISABLED
        },
      )
    }
    buttons.push(
      btn
      |> @ui.Button::new(
        on_click=fn() {
          new_spend_sp_packet(skills[i].id.int_value()).dispatch() // TODO: send after confirm
          @ui.ButtonState::NORMAL
        },
      ),
    )
  }
  buttons.push(
    self.btn_close
    |> @ui.Button::new(
      on_click=fn() {
        model.active = false
        @ui.ButtonState::NORMAL
      },
    ),
  )
  let skills = skills.map(
    fn(meta) {
      {
        name_text: meta.name_text,
        level_text: meta.level_text,
        icon: meta.icon,
        enabled: check_required?(self.attrs.skillbook, meta.id.int_value()).unwrap(), // TODO: handle error
      }
    },
  )
  {
    model,
    sprites: resources.sprites,
    book_icon,
    book_text,
    sp_label,
    skills,
    buttons,
  }
}

///|
fn use_render_state(self : SkillBookUI) -> RenderState {
  match self.render_state {
    Some(ds) => ds
    None => {
      let state = self.logic_state.render(
        self.resources,
        fn() { self.render_state = None },
      )
      self.render_state = Some(state)
      state
    }
  }
}

///|
pub fn draw(self : SkillBookUI, alpha : Double) -> Unit {
  let draw_state = use_render_state(self)
  let resources = self.resources
  let model = draw_state.model
  @ui.draw_sprites(draw_state.sprites.iter(), model.position, alpha)
  draw_state.book_icon.draw(
    model.position + @struct.Point::new(11, 85)
    |> @graphics.DrawArgument::from_point,
  )
  draw_state.book_text.draw(model.position + @struct.Point::new(173, 59))
  draw_state.sp_label.draw(model.position + @struct.Point::new(304, 23))
  let mut skill_position_l = model.position +
    skill_offset +
    @struct.Point::new(-1, 0)
  let mut skill_position_r = model.position +
    skill_offset +
    @struct.Point::new(-1 + row_width, 0)
  for i in 0..<rows {
    let mut pos = skill_position_l
    if i % 2 != 0 {
      pos = skill_position_r
    }
    if i < draw_state.skills.length() {
      let skill = draw_state.skills[i]
      if skill.enabled { // TODO: handle error
        resources.skille.draw(pos |> @graphics.DrawArgument::from_point)
      } else {
        resources.skilld.draw(pos |> @graphics.DrawArgument::from_point)
        // self.skills[i].icon.set_state(StatefulIconState::DISABLED) // TODO: implement
      }
      skill.draw(pos + skill_meta_offset |> @graphics.DrawArgument::from_point)
    } else {
      resources.skillb.draw(pos |> @graphics.DrawArgument::from_point)
    }
    if i < rows - 2 {
      resources.line.draw(
        pos + line_offset |> @graphics.DrawArgument::from_point,
      )
    }
    if i % 2 != 0 {
      skill_position_l = skill_position_l.shift_y(row_height)
      skill_position_r = skill_position_r.shift_y(row_height)
    }
  }
  for button in draw_state.buttons {
    button.object.draw(draw_state.model.position)
  }
}

///|
fn check_required(skillbook : @character.SkillBook, id : Int) -> Bool! {
  let mut required = skillbook.collect_required!(id)
  if required.size() == 0 {
    required = @skill.SkillData::get!(id).req_skills
  }
  for req in required {
    let (req_skill_id, req_level) = req
    let req_skill_level = skillbook.get_level(req_skill_id)
    if req_skill_level < req_level {
      return false
    }
  }
  return true
}

///|
pub fn set_attributes(self : SkillBookUI, attrs : Attributes) -> Unit {
  self.logic_state.attrs = attrs
  self.render_state = None
}

///|
pub fn get_ui_model(self : SkillBookUI) -> @ui.UIModel {
  self.logic_state.model
}

///|
pub fn update(self : SkillBookUI) -> Unit {
  let render_state = use_render_state(self)
  @ui.update_sprites(render_state.sprites.iter())
  for button in render_state.buttons {
    button.object.update()
  }
}

///|
pub fn send_cursor(
  self : SkillBookUI,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let draw_state = use_render_state(self)
  @ui.send_cursor_to_btns(
    draw_state.buttons.iter(),
    draw_state.model.position,
    pressed,
    cursorpos,
  )
}

///|
pub fn remove_cursor(self : SkillBookUI) -> Unit {
  // TODO: implement
}

///|
pub fn send_key(
  self : SkillBookUI,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

///| Requests a skill level increase by spending SP
fn new_spend_sp_packet(skill_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_SP)
  ..write_time()
  ..write_int(skill_id)
}

///|
fn joblevel_by_tab(t : Int) -> @job.Level {
  match t {
    1 => @job.Level::FIRST
    2 => @job.Level::SECOND
    3 => @job.Level::THIRD
    4 => @job.Level::FOURTH
    _ => @job.Level::BEGINNER
  }
}

///|
fn is_upgradable(
  skillbook : @character.SkillBook,
  skill_id : Int,
  tab : Int,
  beginner_sp : Int,
  sp : Int
) -> Bool! {
  let joblevel = joblevel_by_tab(tab)
  if joblevel == @job.Level::BEGINNER && beginner_sp <= 0 {
    return false
  }
  if tab != 0 && sp <= 0 {
    return false
  }
  let level = skillbook.get_level(skill_id)
  let mut masterlevel = skillbook.get_masterlevel(skill_id)
  if masterlevel == 0 {
    masterlevel = @skill.SkillData::get!(skill_id).master_level
  }
  if level >= masterlevel {
    return false
  }
  if skill_id == @skill.SkillId::ANGEL_BLESSING.int_value() {
    false
  } else {
    check_required!(skillbook, skill_id)
  }
}

///|
let beginner_skills : FixedArray[@skill.SkillId] = [
  @skill.SkillId::THREE_SNAILS,
  @skill.SkillId::HEAL,
  @skill.SkillId::FEATHER,
]

///|
fn enumerate[T](iter : Iter[T]) -> Iter2[Int, T] {
  Iter2::new(
    fn(yield) {
      let mut i = 0
      iter.run(
        fn(item) {
          let res = yield(i, item)
          i += 1
          res
        },
      )
    },
  )
}
