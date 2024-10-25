let skill_offset : @struct.Point[Int] = @struct.Point::new(11, 93)

let skill_meta_offset : @struct.Point[Int] = @struct.Point::new(2, 2)

let line_offset : @struct.Point[Int] = @struct.Point::new(0, 37)

let rows : Int = 12

let row_height : Int = 40

let row_width : Int = 143

struct SkillDisplayMeta {
  id : Int
  level : Int
  icon : StatefulIcon
  name_text : @graphics.Text
  level_text : @graphics.Text
}

pub fn SkillDisplayMeta::draw(
  self : SkillDisplayMeta,
  args : @graphics.DrawArgument
) -> Unit {
  self.icon.draw(args.get_pos())
  self.name_text.draw(args.get_pos() + @struct.Point::new(38, -5))
  self.level_text.draw(args.get_pos() + @struct.Point::new(38, 13))
}

struct SkillBookUI {
  base : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  stats : @character.CharStats
  skillbook : @character.SkillBook
  buttons : Map[SkillBookUIButton, @ui.UIButton]
  mut book_icon : @graphics.Texture
  book_text : @graphics.Text
  sp_label : @graphics.Text
  mut job : @job.Job
  mut sp : Int
  mut beginner_sp : Int
  mut tab : Int
  mut skill_count : Int
  mut offset : Int
  skills : Array[SkillDisplayMeta]
  skille : @graphics.Texture
  skilld : @graphics.Texture
  skillb : @graphics.Texture
  line : @graphics.Texture
  bg_dimensions : @struct.Point[Int]
  mut macro_enabled : Bool
  macro_backgrnd : @graphics.Texture
  macro_backgrnd2 : @graphics.Texture
  macro_backgrnd3 : @graphics.Texture
  mut sp_enabled : Bool
  sp_backgrnd : @graphics.Texture
  sp_backgrnd2 : @graphics.Texture
  sp_backgrnd3 : @graphics.Texture
  sp_before : @graphics.Charset
  sp_after : @graphics.Charset
  mut sp_before_text : String
  mut sp_after_text : String
  sp_used : @graphics.Text
  sp_remaining : @graphics.Text
  sp_name : @graphics.Text
  mut sp_id : Int
  mut sp_master_level : Int
}

pub fn SkillBookUI::new(
  skillbook : @character.SkillBook,
  stats : @character.CharStats
) -> SkillBookUI {
  let skillbook = skillbook
  let skill = @resource.ui_loader().load_res(["UIWindow2.img", "Skill"])
  let main = skill["main"]
  let ui_backgrnd = main["backgrnd"]
  let bg_dimensions = @graphics.Texture::get_dimensions(
    ui_backgrnd |> @graphics.Texture::from_resource,
  )
  let skilld = main["skill0"] |> @graphics.Texture::from_resource
  let skille = main["skill1"] |> @graphics.Texture::from_resource
  let skillb = main["skillBlank"] |> @graphics.Texture::from_resource
  let line = main["line"] |> @graphics.Texture::from_resource
  let buttons : Map[SkillBookUIButton, @ui.UIButton] = Map::new()
  buttons[SkillBookUIButton::BT_HYPER] = @ui.MapleButton::from_resource(
    main["BtHyper"],
  )
  buttons[SkillBookUIButton::BT_GUILD_SKILL] = @ui.MapleButton::from_resource(
    main["BtGuildSkill"],
  )
  buttons[SkillBookUIButton::BT_RIDE] = @ui.MapleButton::from_resource(
    main["BtRide"],
  )
  buttons[SkillBookUIButton::BT_MACRO] = @ui.MapleButton::from_resource(
    main["BtMacro"],
  )
  buttons[SkillBookUIButton::BT_HYPER]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[SkillBookUIButton::BT_GUILD_SKILL]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  buttons[SkillBookUIButton::BT_RIDE]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  let skillPoint = @resource.ui_loader().load_res(
    ["UIWindow4.img", "Skill", "skillPoint"],
  )
  let sp_backgrnd = skillPoint["backgrnd"] |> @graphics.Texture::from_resource
  let sp_backgrnd2 = skillPoint["backgrnd2"] |> @graphics.Texture::from_resource
  let sp_backgrnd3 = skillPoint["backgrnd3"] |> @graphics.Texture::from_resource
  buttons[SkillBookUIButton::BT_CANCEL] = @ui.MapleButton::from_resource(
    skillPoint["BtCancle"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_OKAY] = @ui.MapleButton::from_resource(
    skillPoint["BtOkay"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_SP_DOWN] = @ui.MapleButton::from_resource(
    skillPoint["BtSpDown"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_SP_MAX] = @ui.MapleButton::from_resource(
    skillPoint["BtSpMax"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_SP_UP] = @ui.MapleButton::from_resource(
    skillPoint["BtSpUp"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_SP_DOWN]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  let sp_before = @graphics.Charset::new(
    skillPoint["num"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let sp_after = @graphics.Charset::new(
    skillPoint["num"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let sp_used = @graphics.Text::new(
    @graphics.FontId::A12B,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::WHITE,
  )
  let sp_remaining = @graphics.Text::new(
    @graphics.FontId::A12B,
    @graphics.TextAlignment::LEFT,
    @struct.ColorName::SUPERNOVA,
  )
  let sp_name = @graphics.Text::new(
    @graphics.FontId::A12B,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
  )
  let sprites = []
  sprites.push(
    @graphics.Sprite::from_resource(
      ui_backgrnd,
      state_args=@struct.Point::new(1, 0) |> @graphics.DrawArgument::from_point,
    ),
  )
  sprites.push(@graphics.Sprite::from_resource(main["backgrnd2"]))
  sprites.push(@graphics.Sprite::from_resource(main["backgrnd3"]))
  let macro = skill["macro"]
  let macro_backgrnd = macro["backgrnd"] |> @graphics.Texture::from_resource
  let macro_backgrnd2 = macro["backgrnd2"] |> @graphics.Texture::from_resource
  let macro_backgrnd3 = macro["backgrnd3"] |> @graphics.Texture::from_resource
  buttons[SkillBookUIButton::BT_MACRO_OK] = @ui.MapleButton::from_resource(
    macro["BtOK"],
    pos=@struct.Point::new(bg_dimensions.x, 0),
  )
  buttons[SkillBookUIButton::BT_MACRO_OK]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::DISABLED)
  let close = @resource.ui_loader().load_res(["UIBasic.img", "BtClose3"])
  buttons[SkillBookUIButton::BT_CLOSE] = @ui.MapleButton::from_resource(
    close,
    pos=@struct.Point::new(bg_dimensions.x - 23, 6),
  )
  let tab = main["Tab"]
  let enabled = tab["enabled"]
  let disabled = tab["disabled"]
  for
    i, k in [
      SkillBookUIButton::BT_TAB0,
      SkillBookUIButton::BT_TAB1,
      SkillBookUIButton::BT_TAB2,
      SkillBookUIButton::BT_TAB3,
      SkillBookUIButton::BT_TAB4,
    ] {
    buttons[k] = @ui.TwoSpriteButton::new(
      disabled[i.to_string()],
      enabled[i.to_string()],
    )
  }
  let mut y_adj = 0
  for
    i, k in [
      SkillBookUIButton::BT_SP_UP0,
      SkillBookUIButton::BT_SP_UP1,
      SkillBookUIButton::BT_SP_UP2,
      SkillBookUIButton::BT_SP_UP3,
      SkillBookUIButton::BT_SP_UP4,
      SkillBookUIButton::BT_SP_UP5,
      SkillBookUIButton::BT_SP_UP6,
      SkillBookUIButton::BT_SP_UP7,
      SkillBookUIButton::BT_SP_UP8,
      SkillBookUIButton::BT_SP_UP9,
      SkillBookUIButton::BT_SP_UP10,
      SkillBookUIButton::BT_SP_UP11,
    ] {
    let mut x_adj = 0
    if i % 2 != 0 {
      x_adj = row_width
    }
    let spup_position = skill_offset +
      @struct.Point::new(124 + x_adj, 20 + y_adj)
    buttons[k] = @ui.MapleButton::from_resource(
      main["BtSpUp"],
      pos=spup_position,
    )
    if i % 2 != 0 {
      y_adj += row_height
    }
  }
  let book_text = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    max_width=150,
  )
  let sp_label = @graphics.Text::new(
    @graphics.FontId::A12M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )

  // TODO: slider
  // TODO: job
  let dimension = bg_dimensions
  let base = @ui.UIModel::new(@struct.Point::default(), dimension)
  let ui : SkillBookUI = {
    base,
    sprites,
    stats,
    skillbook,
    buttons,
    book_text,
    sp_label,
    job: @job.Job::new(),
    book_icon: @graphics.Texture::default(),
    sp: 0,
    beginner_sp: 0,
    tab: 0,
    skill_count: 0,
    offset: 0,
    skills: [],
    skille,
    skilld,
    skillb,
    line,
    bg_dimensions,
    macro_enabled: false,
    macro_backgrnd,
    macro_backgrnd2,
    macro_backgrnd3,
    sp_enabled: false,
    sp_backgrnd,
    sp_backgrnd2,
    sp_backgrnd3,
    sp_before,
    sp_after,
    sp_before_text: "",
    sp_after_text: "",
    sp_used,
    sp_remaining,
    sp_name,
    sp_id: 0,
    sp_master_level: 0,
  }
  ui.set_skillpoint(false)
  ui.change_job?(stats.job.get_id()).unwrap() // TODO: handle error
  ui
}

pub fn draw(self : SkillBookUI, alpha : Double) -> Unit {
  @ui.draw_sprites(self.sprites.iter(), self.base.position, alpha)
  self.book_icon.draw(
    self.base.position + @struct.Point::new(11, 85)
    |> @graphics.DrawArgument::from_point,
  )
  self.book_text.draw(self.base.position + @struct.Point::new(173, 59))
  self.sp_label.draw(self.base.position + @struct.Point::new(304, 23))
  let mut skill_position_l = self.base.position +
    skill_offset +
    @struct.Point::new(-1, 0)
  let mut skill_position_r = self.base.position +
    skill_offset +
    @struct.Point::new(-1 + row_width, 0)
  for i in 0..<rows {
    let mut pos = skill_position_l
    if i % 2 != 0 {
      pos = skill_position_r
    }
    if i < self.skills.length() {
      if self.check_required?(self.skills[i].id).unwrap() { // TODO: handle error
        self.skille.draw(pos |> @graphics.DrawArgument::from_point)
      } else {
        self.skilld.draw(pos |> @graphics.DrawArgument::from_point)
        // self.skills[i].icon.set_state(StatefulIconState::DISABLED) // TODO: implement
      }
      self.skills[i].draw(
        pos + skill_meta_offset |> @graphics.DrawArgument::from_point,
      )
    } else {
      self.skillb.draw(pos |> @graphics.DrawArgument::from_point)
    }
    if i < rows - 2 {
      self.line.draw(pos + line_offset |> @graphics.DrawArgument::from_point)
    }
    if i % 2 != 0 {
      skill_position_l = skill_position_l.shift_y(row_height)
      skill_position_r = skill_position_r.shift_y(row_height)
    }
  }

  // TODO: slider
  if self.macro_enabled {
    let macro_pos = self.base.position +
      @struct.Point::new(self.bg_dimensions.x, 0)
    self.macro_backgrnd.draw(
      macro_pos + @struct.Point::new(1, 0) |> @graphics.DrawArgument::from_point,
    )
    self.macro_backgrnd2.draw(macro_pos |> @graphics.DrawArgument::from_point)
    self.macro_backgrnd3.draw(macro_pos |> @graphics.DrawArgument::from_point)
  }
  if self.sp_enabled {
    let sp_pos = self.base.position +
      @struct.Point::new(self.bg_dimensions.x, 0)
    self.sp_backgrnd.draw(sp_pos |> @graphics.DrawArgument::from_point)
    self.sp_backgrnd2.draw(sp_pos |> @graphics.DrawArgument::from_point)
    self.sp_backgrnd3.draw(sp_pos |> @graphics.DrawArgument::from_point)
    let sp_level_pos = sp_pos + @struct.Point::new(78, 149)
    self.sp_before.draw_text_with_hspace(
      self.sp_before_text,
      12,
      sp_level_pos |> @graphics.DrawArgument::from_point,
    )
    |> ignore
    self.sp_after.draw_text_with_hspace(
      self.sp_after_text,
      11,
      sp_level_pos + @struct.Point::new(78, 0)
      |> @graphics.DrawArgument::from_point,
    )
    |> ignore
    self.sp_used.draw(sp_pos + @struct.Point::new(82, 87))
  }
  for _, button in self.buttons {
    button.draw(self.base.position)
  }
}

fn check_required(self : SkillBookUI, id : Int) -> Bool! {
  let mut required = self.skillbook.collect_required!(id)
  if required.size() == 0 {
    required = @skill.SkillData::get!(id).req_skills
  }
  for req in required {
    let (req_skill_id, req_level) = req
    let req_skill_level = self.skillbook.get_level(req_skill_id)
    if req_skill_level < req_level {
      return false
    }
  }
  return true
}

enum SkillBookUIButton {
  BT_CLOSE
  BT_HYPER
  BT_GUILD_SKILL
  BT_RIDE
  BT_MACRO
  BT_MACRO_OK
  BT_CANCEL
  BT_OKAY
  BT_SP_DOWN
  BT_SP_MAX
  BT_SP_UP
  BT_TAB0
  BT_TAB1
  BT_TAB2
  BT_TAB3
  BT_TAB4
  BT_SP_UP0
  BT_SP_UP1
  BT_SP_UP2
  BT_SP_UP3
  BT_SP_UP4
  BT_SP_UP5
  BT_SP_UP6
  BT_SP_UP7
  BT_SP_UP8
  BT_SP_UP9
  BT_SP_UP10
  BT_SP_UP11
} derive(Eq, Hash)

pub fn SkillBookUI::is_focused() -> Bool {
  return false
}

pub fn get_ui_model(self : SkillBookUI) -> @ui.UIModel {
  return self.base
}

pub fn update(self : SkillBookUI) -> Unit {
  @ui.update_sprites(self.sprites.iter())
  for _, button in self.buttons {
    button.update()
  }
}

pub fn send_cursor(
  self : SkillBookUI,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  // TODO: implement
  @ui.send_cursor_to_buttons(
    self.buttons.iter2(),
    self.base.position,
    fn(buttonid) {
      self
      .button_pressed?(buttonid)
      .unwrap() // TODO: handle error
    },
    pressed,
    cursorpos,
  )
}

pub fn button_pressed(
  self : SkillBookUI,
  buttonid : SkillBookUIButton
) -> @ui.ButtonState! {
  let cur_sp = @strconv.parse_int!(self.sp_label.get_text())
  fn press_tab!(tab) {
    self.change_tab!(tab)
    @ui.ButtonState::PRESSED
  }

  fn press_sp_up!(sp_pos) {
    self.send_spup!(sp_pos + self.offset)
  }

  match buttonid {
    SkillBookUIButton::BT_CLOSE => self.close()
    SkillBookUIButton::BT_MACRO => self.set_macro(self.macro_enabled.not())
    SkillBookUIButton::BT_CANCEL => self.set_skillpoint(false)
    SkillBookUIButton::BT_OKAY => {
      let mut used = @strconv.parse_int!(self.sp_used.get_text())
      while used > 0 {
        self.spend_sp(self.sp_id)
        used -= 1
      }
      self.change_sp!()
      self.set_skillpoint(false)
    }
    SkillBookUIButton::BT_SP_DOWN => {
      let mut used = @strconv.parse_int!(self.sp_used.get_text())
      let mut sp_after = @strconv.parse_int!(self.sp_after_text)
      let sp_before = @strconv.parse_int!(self.sp_before_text)
      used -= 1
      sp_after -= 1
      self.sp_after_text = sp_after.to_string()
      self.sp_used.change_text(used.to_string())
      self.sp_remaining.change_text((cur_sp - used).to_string())
      self.buttons[SkillBookUIButton::BT_SP_UP]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
      self.buttons[SkillBookUIButton::BT_SP_MAX]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
      if sp_after - 1 == sp_before {
        return @ui.ButtonState::DISABLED
      }
      return @ui.ButtonState::NORMAL
    }
    SkillBookUIButton::BT_SP_MAX => {
      let mut used = @strconv.parse_int!(self.sp_used.get_text())
      let sp_before = @strconv.parse_int!(self.sp_before_text)
      let sp_touse = self.sp_master_level - sp_before - used
      used += sp_touse
      self.sp_after_text = self.sp_master_level.to_string()
      self.sp_used.change_text(used.to_string())
      self.sp_remaining.change_text((cur_sp - used).to_string())
      self.buttons[SkillBookUIButton::BT_SP_UP]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::DISABLED)
      self.buttons[SkillBookUIButton::BT_SP_DOWN]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
      return @ui.ButtonState::DISABLED
    }
    SkillBookUIButton::BT_SP_UP => {
      let mut used = @strconv.parse_int!(self.sp_used.get_text())
      let mut sp_after = @strconv.parse_int!(self.sp_after_text)
      used += 1
      sp_after += 1
      self.sp_after_text = sp_after.to_string()
      self.sp_used.change_text(used.to_string())
      self.sp_remaining.change_text((cur_sp - used).to_string())
      self.buttons[SkillBookUIButton::BT_SP_DOWN]
      .unwrap()
      .get_button_base()
      .set_state(@ui.ButtonState::NORMAL)
      if sp_after == self.sp_master_level {
        self.buttons[SkillBookUIButton::BT_SP_MAX]
        .unwrap()
        .get_button_base()
        .set_state(@ui.ButtonState::DISABLED)
        return @ui.ButtonState::DISABLED
      }
      return @ui.ButtonState::NORMAL
    }
    SkillBookUIButton::BT_TAB0 => return press_tab!(0)
    SkillBookUIButton::BT_TAB1 => return press_tab!(1)
    SkillBookUIButton::BT_TAB2 => return press_tab!(2)
    SkillBookUIButton::BT_TAB3 => return press_tab!(3)
    SkillBookUIButton::BT_TAB4 => return press_tab!(4)
    SkillBookUIButton::BT_SP_UP0 => press_sp_up!(0)
    SkillBookUIButton::BT_SP_UP1 => press_sp_up!(1)
    SkillBookUIButton::BT_SP_UP2 => press_sp_up!(2)
    SkillBookUIButton::BT_SP_UP3 => press_sp_up!(3)
    SkillBookUIButton::BT_SP_UP4 => press_sp_up!(4)
    SkillBookUIButton::BT_SP_UP5 => press_sp_up!(5)
    SkillBookUIButton::BT_SP_UP6 => press_sp_up!(6)
    SkillBookUIButton::BT_SP_UP7 => press_sp_up!(7)
    SkillBookUIButton::BT_SP_UP8 => press_sp_up!(8)
    SkillBookUIButton::BT_SP_UP9 => press_sp_up!(9)
    SkillBookUIButton::BT_SP_UP10 => press_sp_up!(10)
    SkillBookUIButton::BT_SP_UP11 => press_sp_up!(11)
    _ => ()
  }
  @ui.ButtonState::IDENTITY
}

pub fn remove_cursor(self : SkillBookUI) -> Unit {
  // TODO: implement
}

pub fn get_type(self : SkillBookUI) -> @ui.UIElementType {
  @ui.SKILL_BOOK
}

pub fn send_key(
  self : SkillBookUI,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

fn is_skillpoint_enabled(self : SkillBookUI) -> Bool {
  return self.sp_enabled
}

fn set_skillpoint(self : SkillBookUI, sp_enabled : Bool) -> Unit {
  self.sp_enabled = sp_enabled
  if sp_enabled {
    self.base.dimension = self.bg_dimensions +
      @struct.Point::new(self.sp_backgrnd.get_dimensions().x, 0)
  } else if self.macro_enabled.not() {
    self.base.dimension = self.bg_dimensions
  }
  self.buttons[SkillBookUIButton::BT_CANCEL]
  .unwrap()
  .get_button_base()
  .set_active(sp_enabled)
  self.buttons[SkillBookUIButton::BT_OKAY]
  .unwrap()
  .get_button_base()
  .set_active(sp_enabled)
  self.buttons[SkillBookUIButton::BT_SP_DOWN]
  .unwrap()
  .get_button_base()
  .set_active(sp_enabled)
  self.buttons[SkillBookUIButton::BT_SP_MAX]
  .unwrap()
  .get_button_base()
  .set_active(sp_enabled)
  self.buttons[SkillBookUIButton::BT_SP_UP]
  .unwrap()
  .get_button_base()
  .set_active(sp_enabled)
  if sp_enabled && self.macro_enabled {
    self.set_macro(false)
  }
}

fn set_macro(self : SkillBookUI, enabled : Bool) -> Unit {
  self.macro_enabled = enabled
  if enabled {
    self.base.dimension = self.bg_dimensions +
      @struct.Point::new(self.macro_backgrnd.get_dimensions().x, 0)
  } else if self.sp_enabled.not() {
    self.base.dimension = self.bg_dimensions
  }
  self.buttons[BT_MACRO_OK]
  .unwrap()
  .get_button_base()
  .set_active(self.macro_enabled)
  if self.macro_enabled && self.sp_enabled {
    self.set_skillpoint(false)
  }
}

fn close(self : SkillBookUI) -> Unit {
  // self.clear_tooltip()
  self.base.deactivate()
}

fn spend_sp(self : SkillBookUI, skill_id : Int) -> Unit {
  new_spend_sp_packet(skill_id).dispatch()
  // @ui.UI::get().disable()
}

/// Requests a skill level increase by spending SP
fn new_spend_sp_packet(skill_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_SP)
  ..write_time()
  ..write_int(skill_id)
}

fn change_tab(self : SkillBookUI, new_tab : Int) -> Unit! {
  let btn_id = get_button_by_tab(self, new_tab)
  self.buttons[btn_id]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::NORMAL)
  self.buttons[btn_id]
  .unwrap()
  .get_button_base()
  .set_state(@ui.ButtonState::PRESSED)
  self.tab = new_tab
  self.skills.clear()
  self.skill_count = 0
  let joblevel = joblevel_by_tab(new_tab)
  let subid = self.job.get_subjob(joblevel)
  let data = @job.JobData::get(subid)
  self.book_icon = data.icon
  self.book_text.change_text(data.name)
  for skill_id in data.skills {
    let level = self.skillbook.get_level(skill_id)
    let masterlevel = self.skillbook.get_masterlevel(skill_id)
    let invisible = @skill.SkillData::get!(skill_id).invisible
    if invisible && masterlevel == 0 {
      continue
    }
    self.skills.push(SkillDisplayMeta::new?(skill_id, level).unwrap())
    self.skill_count += 1
  }
  self.change_offset!(0)
  self.change_sp!()
}

fn get_button_by_tab(self : SkillBookUI, tab : Int) -> SkillBookUIButton {
  match tab {
    0 => SkillBookUIButton::BT_TAB0
    1 => SkillBookUIButton::BT_TAB1
    2 => SkillBookUIButton::BT_TAB2
    3 => SkillBookUIButton::BT_TAB3
    4 => SkillBookUIButton::BT_TAB4
    _ => panic()
  }
}

fn SkillDisplayMeta::new(id : Int, level : Int) -> SkillDisplayMeta! {
  let data = @skill.SkillData::get!(id)
  let ntx = data.icons[0]
  let dtx = data.icons[1]
  let motx = data.icons[2]
  let icon = StatefulIcon::new(
    // SkillIcon::new(id), // TODO: implement
    ntx, dtx, motx,
  )
  let mut namestr = data.name
  let levelstr = level.to_string()
  let name_text = @graphics.Text::new(
    text=namestr,
    @graphics.FontId::A11M,
    @graphics.TextAlignment::LEFT,
    @struct.ColorName::EMPEROR,
  )
  let level_text = @graphics.Text::new(
    text=levelstr,
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
  { name_text, level_text, icon, id, level }
}

fn joblevel_by_tab(t : Int) -> @job.Level {
  match t {
    1 => @job.Level::FIRST
    2 => @job.Level::SECOND
    3 => @job.Level::THIRD
    4 => @job.Level::FOURTH
    _ => @job.Level::BEGINNER
  }
}

fn change_sp(self : SkillBookUI) -> Unit! {
  let joblevel = joblevel_by_tab(self.tab)
  let level = self.stats.level
  match joblevel {
    @job.Level::BEGINNER => {
      let mut remaining_beginner_sp = if level >= 7 { 6 } else { level - 1 }
      for i in 0..<self.skills.length() {
        let skillid = self.skills[i].id
        if skillid == @skill.SkillId::THREE_SNAILS.int_value() ||
          skillid == @skill.SkillId::HEAL.int_value() ||
          skillid == @skill.SkillId::FEATHER.int_value() {
          remaining_beginner_sp -= self.skills[i].level
        }
      }
      self.beginner_sp = remaining_beginner_sp
      self.sp_label.change_text(self.beginner_sp.to_string())
    }
    _ => {
      self.sp = self.stats.sp
      self.sp_label.change_text(self.sp.to_string())
    }
  }
  self.change_offset!(self.offset)
  self.set_skillpoint(false)
}

fn change_offset(self : SkillBookUI, new_offset : Int) -> Unit! {
  self.offset = new_offset
  for
    i, index in [
      SkillBookUIButton::BT_SP_UP0,
      SkillBookUIButton::BT_SP_UP1,
      SkillBookUIButton::BT_SP_UP2,
      SkillBookUIButton::BT_SP_UP3,
      SkillBookUIButton::BT_SP_UP4,
      SkillBookUIButton::BT_SP_UP5,
      SkillBookUIButton::BT_SP_UP6,
      SkillBookUIButton::BT_SP_UP7,
      SkillBookUIButton::BT_SP_UP8,
      SkillBookUIButton::BT_SP_UP9,
      SkillBookUIButton::BT_SP_UP10,
      SkillBookUIButton::BT_SP_UP11,
    ] {
    let row = self.offset + i
    self.buttons[index]
    .unwrap()
    .get_button_base()
    .set_active(row < self.skill_count)
    if row < self.skills.length() {
      let skill_id = self.skills[row].id
      let canraise = self.can_raise!(skill_id)
      self.buttons[index]
      .unwrap()
      .get_button_base()
      .set_state(
        if canraise {
          @ui.ButtonState::NORMAL
        } else {
          @ui.ButtonState::DISABLED
        },
      )
    }
  }
}

fn can_raise(self : SkillBookUI, skill_id : Int) -> Bool! {
  let joblevel = joblevel_by_tab(self.tab)
  if joblevel == @job.Level::BEGINNER && self.beginner_sp <= 0 {
    return false
  }
  if self.tab != 0 && self.sp <= 0 {
    return false
  }
  let level = self.skillbook.get_level(skill_id)
  let mut masterlevel = self.skillbook.get_masterlevel(skill_id)
  if masterlevel == 0 {
    masterlevel = @skill.SkillData::get!(skill_id).master_level
  }
  if level >= masterlevel {
    return false
  }
  if skill_id == @skill.SkillId::ANGEL_BLESSING.int_value() {
    false
  } else {
    self.check_required!(skill_id)
  }
}

fn send_spup(self : SkillBookUI, row : Int) -> Unit! {
  if row >= self.skills.length() {
    return
  }
  let id = self.skills[row].id
  if self.sp_enabled && id == self.sp_id {
    self.set_skillpoint(false)
    return
  }
  let level = self.skills[row].level
  let used = 1
  let skillData = @skill.SkillData::get!(id)
  let name = skillData.name
  let cur_sp = @strconv.parse_int!(self.sp_label.get_text())
  self.sp_before_text = level.to_string()
  self.sp_after_text = (level + used).to_string()
  self.sp_used.change_text(used.to_string())
  self.sp_remaining.change_text((cur_sp - used).to_string())
  self.sp_name.change_text(name)
  self.sp_id = id
  self.sp_master_level = skillData.master_level
  if self.sp_master_level == 1 {
    self.buttons[SkillBookUIButton::BT_SP_DOWN]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::DISABLED)
    self.buttons[SkillBookUIButton::BT_SP_MAX]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::DISABLED)
    self.buttons[SkillBookUIButton::BT_SP_UP]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::DISABLED)
  } else {
    self.buttons[SkillBookUIButton::BT_SP_DOWN]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::DISABLED)
    self.buttons[SkillBookUIButton::BT_SP_MAX]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::NORMAL)
    self.buttons[SkillBookUIButton::BT_SP_UP]
    .unwrap()
    .get_button_base()
    .set_state(@ui.ButtonState::NORMAL)
  }
  if self.sp_enabled.not() {
    self.set_skillpoint(true)
  }
}

fn change_job(self : SkillBookUI, id : Int) -> Unit! {
  self.job = @job.Job::new(~id)
  let level = self.job.get_level()
  for
    btn in [
      SkillBookUIButton::BT_TAB0,
      SkillBookUIButton::BT_TAB1,
      SkillBookUIButton::BT_TAB2,
      SkillBookUIButton::BT_TAB3,
      SkillBookUIButton::BT_TAB4,
    ] {
    self.buttons[btn]
    .unwrap()
    .get_button_base()
    .set_active(btn_id_to_joblevel(btn) <= level)
  }
  self.change_tab!(level.int_value() - @job.Level::BEGINNER.int_value())
}

fn btn_id_to_joblevel(btn : SkillBookUIButton) -> @job.Level {
  match btn {
    SkillBookUIButton::BT_TAB0 => @job.Level::BEGINNER
    SkillBookUIButton::BT_TAB1 => @job.Level::FIRST
    SkillBookUIButton::BT_TAB2 => @job.Level::SECOND
    SkillBookUIButton::BT_TAB3 => @job.Level::THIRD
    SkillBookUIButton::BT_TAB4 => @job.Level::FOURTH
    _ => panic()
  }
}
