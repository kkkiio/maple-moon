let skill_offset : @struct.Point[Int] = @struct.Point::new(11, 93)

let skill_meta_offset : @struct.Point[Int] = @struct.Point::new(2, 2)

let line_offset : @struct.Point[Int] = @struct.Point::new(0, 37)

let rows : Int = 12

let row_height : Int = 40

let row_width : Int = 143

struct SkillDisplayMeta {
  id : @skill.SkillId
  icon : StatefulIcon
  name_text : @graphics.Text
  level_text : @graphics.Text
}

struct RenderState {
  model : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  stats : @character.CharStats
  skillbook : @character.SkillBook
  job : @job.Job
  tab_resources : Array[TabResource]
  btn_close : @ui.MapleButton
  btn_hyper : @ui.MapleButton
  btn_guild_skill : @ui.MapleButton
  btn_ride : @ui.MapleButton
  sp_before : @graphics.Charset
  sp_after : @graphics.Charset
  bg_dimensions : @struct.Point[Int]
  sp_up_btns : Array[@ui.MapleButton]
  mut tab : Int
  mut sp_enabled : Bool
}

struct TabResource {
  tab_btn_disabled_tex : @graphics.Texture
  tab_btn_enabled_tex : @graphics.Texture
  skills : Array[SkillDisplayMeta]
  book_icon : @graphics.Texture
  book_name : String
}

struct DrawState {
  model : @ui.UIModel
  sprites : Array[@graphics.Sprite]
  buttons : Array[@ui.Button]
  book_icon : @graphics.Texture
  book_text : @graphics.Text
  sp_label : @graphics.Text
  skills : Array[SkillDrawState]
  sp_before : @graphics.GameText
  sp_after : @graphics.GameText
  sp_enabled : Bool
}

struct SkillDrawState {
  enabled : Bool
  icon : StatefulIcon
  name_text : @graphics.Text
  level_text : @graphics.Text
}

struct Resources {
  line : @graphics.Texture
  sp_backgrnd : @graphics.Texture
  sp_backgrnd2 : @graphics.Texture
  sp_backgrnd3 : @graphics.Texture
  skille : @graphics.Texture
  skilld : @graphics.Texture
  skillb : @graphics.Texture
}

fn draw(self : SkillDrawState, args : @graphics.DrawArgument) -> Unit {
  self.icon.draw(args.get_pos())
  self.name_text.draw(args.get_pos() + @struct.Point::new(38, -5))
  self.level_text.draw(args.get_pos() + @struct.Point::new(38, 13))
}

struct SkillBookUI {
  render_state : RenderState
  resources : Resources
  mut draw_state : DrawState?
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
  let job = stats.job
  let curr_job_level = job.get_level()
  let skillPoint = @resource.ui_loader().load_res(
    ["UIWindow4.img", "Skill", "skillPoint"],
  )
  let sp_backgrnd = skillPoint["backgrnd"] |> @graphics.Texture::from_resource
  let sp_backgrnd2 = skillPoint["backgrnd2"] |> @graphics.Texture::from_resource
  let sp_backgrnd3 = skillPoint["backgrnd3"] |> @graphics.Texture::from_resource
  let sp_before = @graphics.Charset::new(
    skillPoint["num"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let sp_after = @graphics.Charset::new(
    skillPoint["num"],
    @graphics.CharsetAlignment::RIGHT,
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
  let close = @resource.ui_loader().load_res(["Basic.img", "BtClose3"])
  let btn_close = @ui.MapleButton::from_resource(
    close,
    pos=@struct.Point::new(bg_dimensions.x - 23, 6),
  )
  let tab_resources = []
  let tab_res = main["Tab"]
  let enabled = tab_res["enabled"]
  let disabled = tab_res["disabled"]
  for i, level in @job.get_levels(upto=curr_job_level) |> enumerate {
    let skills = []
    let subid = job.get_subjob(level)
    let job_data = @job.JobData::get(subid)
    for skill_id in job_data.skills {
      let level = skillbook.get_level(skill_id)
      let masterlevel = skillbook.get_masterlevel(skill_id)
      let invisible = @skill.SkillData::get?(skill_id).unwrap().invisible // TODO: handle error
      if invisible && masterlevel == 0 {
        continue
      }
      skills.push(SkillDisplayMeta::new?(skill_id, level).unwrap())
    }
    let subid = job.get_subjob(level)
    let data = @job.JobData::get(subid)
    tab_resources.push(
      {
        tab_btn_disabled_tex: disabled[i.to_string()]
        |> @graphics.Texture::from_resource,
        tab_btn_enabled_tex: enabled[i.to_string()]
        |> @graphics.Texture::from_resource,
        skills,
        book_icon: data.icon,
        book_name: data.name,
      },
    )
  }
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
  {
    render_state: {
      model,
      sprites,
      stats,
      skillbook,
      job,
      tab_resources,
      btn_close,
      btn_hyper,
      btn_guild_skill,
      btn_ride,
      sp_before,
      sp_after,
      bg_dimensions,
      sp_up_btns,
      tab: 0,
      sp_enabled: false,
    },
    resources: {
      line,
      sp_backgrnd,
      sp_backgrnd2,
      sp_backgrnd3,
      skille,
      skilld,
      skillb,
    },
    draw_state: None,
  }
}

fn render(self : RenderState, on_state_changed : () -> Unit) -> DrawState {
  let buttons = []
  buttons.push(self.btn_hyper |> @ui.Button::new)
  buttons.push(self.btn_guild_skill |> @ui.Button::new)
  buttons.push(self.btn_ride |> @ui.Button::new)
  for i, tab_resource in self.tab_resources {
    buttons.push(
      @ui.TwoSpriteButton::new(
        tab_resource.tab_btn_disabled_tex,
        tab_resource.tab_btn_enabled_tex,
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
  let book_text = @graphics.Text::new(
    @graphics.FontId::A11M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    max_width=150,
    text=self.tab_resources[self.tab].book_name,
  )
  let joblevel = self.job.get_level()
  let level = self.stats.level
  let skills = self.tab_resources[self.tab].skills
  let beginner_sp = @math.minimum(level - 1, 6) -
    skills
    .iter()
    .filter(fn(skill) { beginner_skills.contains(skill.id) })
    .count()
  let sp = match joblevel {
    @job.Level::BEGINNER => beginner_sp
    _ => self.stats.sp
  }
  let sp_label = @graphics.Text::new(
    text=sp.to_string(),
    @graphics.FontId::A12M,
    @graphics.TextAlignment::RIGHT,
    @struct.ColorName::BLACK,
  )
  let sp_before_text = level.to_string()
  let sp_after_text = (level + sp).to_string()
  let sp_before = @graphics.GameText::new(self.sp_before, sp_before_text, 12)
  let sp_after = @graphics.GameText::new(self.sp_after, sp_after_text, 11)
  let model = self.model
  for i, btn in self.sp_up_btns {
    btn.get_button_base().set_active(i < skills.length())
    if i < skills.length() {
      let skill_id = skills[i].id
      let canraise = is_upgradable?(
        self.skillbook,
        skill_id.int_value(),
        self.tab,
        beginner_sp,
        self.stats.sp,
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
  let book_icon = self.tab_resources[self.tab].book_icon
  let sprites = self.sprites
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
        enabled: check_required?(self.skillbook, meta.id.int_value()).unwrap(), // TODO: handle error
      }
    },
  )
  {
    model,
    sprites,
    book_icon,
    book_text,
    sp_label,
    skills,
    sp_before,
    sp_after,
    sp_enabled: self.sp_enabled,
    buttons,
  }
}

fn use_draw_state(self : SkillBookUI) -> DrawState {
  match self.draw_state {
    Some(ds) => ds
    None => {
      let state = self.render_state.render(fn() { self.draw_state = None })
      self.draw_state = Some(state)
      state
    }
  }
}

pub fn draw(self : SkillBookUI, alpha : Double) -> Unit {
  let draw_state = use_draw_state(self)
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
  if draw_state.sp_enabled {
    let sp_pos = model.position + @struct.Point::new(model.dimension.x, 0)
    resources.sp_backgrnd.draw(sp_pos |> @graphics.DrawArgument::from_point)
    resources.sp_backgrnd2.draw(sp_pos |> @graphics.DrawArgument::from_point)
    resources.sp_backgrnd3.draw(sp_pos |> @graphics.DrawArgument::from_point)
    let sp_level_pos = sp_pos + @struct.Point::new(78, 149)
    draw_state.sp_before.draw(
      sp_level_pos |> @graphics.DrawArgument::from_point,
    )
    |> ignore
    draw_state.sp_after.draw(
      sp_level_pos + @struct.Point::new(78, 0)
      |> @graphics.DrawArgument::from_point,
    )
    |> ignore
    // draw_state.sp_used.draw(sp_pos + @struct.Point::new(82, 87))
  }
  for button in draw_state.buttons {
    button.object.draw(draw_state.model.position)
  }
}

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

pub fn SkillBookUI::is_focused() -> Bool {
  return false
}

pub fn get_ui_model(self : SkillBookUI) -> @ui.UIModel {
  self.render_state.model
}

pub fn update(self : SkillBookUI) -> Unit {
  @ui.update_sprites(self.render_state.sprites.iter())
  let draw_state = use_draw_state(self)
  for button in draw_state.buttons {
    button.object.update()
  }
}

pub fn send_cursor(
  self : SkillBookUI,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let draw_state = use_draw_state(self)
  @ui.send_cursor_to_btns(
    draw_state.buttons.iter(),
    draw_state.model.position,
    pressed,
    cursorpos,
  )
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

fn set_skillpoint(
  self : RenderState,
  sp_enabled : Bool,
  sp_backgrnd : @graphics.Sprite
) -> Unit {
  self.sp_enabled = sp_enabled
  // TODO: remove redudant status
  let model = self.model
  if sp_enabled {
    model.dimension = self.bg_dimensions +
      @struct.Point::new(sp_backgrnd.get_dimensions().x, 0)
  } else {
    model.dimension = self.bg_dimensions
  }
}

/// Requests a skill level increase by spending SP
fn new_spend_sp_packet(skill_id : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_SP)
  ..write_time()
  ..write_int(skill_id)
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
  { name_text, level_text, icon, id: @skill.SkillId::from_int?(id).unwrap() } // TODO: handle error
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

let beginner_skills : FixedArray[@skill.SkillId] = [
  @skill.SkillId::THREE_SNAILS,
  @skill.SkillId::HEAL,
  @skill.SkillId::FEATHER,
]

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
