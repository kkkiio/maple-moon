///|
struct UIStatsInfo {
  model : @ui.UIModel
  stats : CharStats
  btn_close : @ui.Button
  btn_hp : @ui.Button
  btn_mp : @ui.Button
  btn_str : @ui.Button
  btn_dex : @ui.Button
  btn_int : @ui.Button
  btn_luk : @ui.Button
  btn_auto : @ui.Button
  btn_hyper_stat_open : @ui.Button
  btn_hyper_stat_close : @ui.Button
  btn_detail_open : @ui.Button
  btn_detail_close : @ui.Button
  btn_ability : @ui.Button
  btn_detail_detail_close : @ui.Button
  sprites : Array[@graphics.Sprite]
  none_ability : @graphics.Texture
  inner_ability : @utils.BoolPair[@graphics.Texture]
  textures_detail : Array[@graphics.Texture]
  show_detail : Bool
  mut has_ap : Bool
  // Normal stats
  name_label : StatLabel
  job_label : StatLabel
  guild_label : StatLabel
  fame_label : StatLabel
  damage_label : StatLabel
  hp_label : StatLabel
  mp_label : StatLabel
  ap_label : StatLabel
  str_label : StatLabel
  dex_label : StatLabel
  int_label : StatLabel
  luk_label : StatLabel
  // Detailed stats
  damage_detailed_label : StatLabel
  damage_bonus_label : StatLabel
  final_damage_label : StatLabel
  ignore_defense_label : StatLabel
  critical_rate_label : StatLabel
  critical_damage_label : StatLabel
  knockback_resistance_label : StatLabel
  defense_label : StatLabel
  speed_label : StatLabel
  jump_label : StatLabel
}

///|
fn UIStatsInfo::new(
  stats : CharStats,
  stat : @resource.NxNode,
  hooks : @ui.Hooks
) -> UIStatsInfo {
  let model = @ui.UIModel::new(
    @struct.Point::new(212, 20),
    @struct.Point::new(212, 318),
  )
  let close = @ui.common_ui_loader().load_res(["Basic.img", "BtClose3"])
  let main = stat["main"]
  let detail = stat["detail"]
  let ability_title = detail["abilityTitle"]
  let metier_line = detail["metierLine"]
  let sprites = [
    main["backgrnd"] |> @graphics.Sprite::from_resource,
    main["backgrnd2"] |> @graphics.Sprite::from_resource,
    main["backgrnd3"] |> @graphics.Sprite::from_resource,
  ]
  let textures_detail = [
    detail["backgrnd"] |> @graphics.Texture::from_resource,
    detail["backgrnd2"] |> @graphics.Texture::from_resource,
    detail["backgrnd3"] |> @graphics.Texture::from_resource,
    detail["backgrnd4"] |> @graphics.Texture::from_resource,
  ]
  let none_ability = ability_title["normal"]["0"]
    |> @graphics.Texture::from_resource
  let inner_ability = @utils.BoolPair::new(
    metier_line["activated"]["0"] |> @graphics.Texture::from_resource,
    metier_line["disabled"]["0"] |> @graphics.Texture::from_resource,
  )
  let btn_close = @ui.MapleButton::from_resource(
      close,
      pos=@struct.Point::new(190, 6),
    )
    |> @ui.Button::new(on_click=fn() {
      model.deactivate()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_hp = @ui.MapleButton::from_resource(main["BtHpUp"])
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::HP).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_mp = @ui.MapleButton::from_resource(
      main["BtHpUp"],
      pos=@struct.Point::new(0, 18),
    )
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::MP).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_str = @ui.MapleButton::from_resource(
      main["BtHpUp"],
      pos=@struct.Point::new(0, 87),
    )
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::STR).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_dex = @ui.MapleButton::from_resource(
      main["BtHpUp"],
      pos=@struct.Point::new(0, 105),
    )
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::DEX).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_int = @ui.MapleButton::from_resource(
      main["BtHpUp"],
      pos=@struct.Point::new(0, 123),
    )
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::INT).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_luk = @ui.MapleButton::from_resource(
      main["BtHpUp"],
      pos=@struct.Point::new(0, 141),
    )
    |> @ui.Button::new(on_click=fn() {
      new_spend_ap_packet(@maple_stat.Id::LUK).dispatch()
      Some(@ui.ButtonState::NORMAL)
    })
  let btn_auto = @ui.MapleButton::from_resource(main["BtAuto"])
    |> @ui.Button::new() // TODO
  let btn_hyper_stat_open = @ui.MapleButton::from_resource(
      main["BtHyperStatOpen"],
    )
    |> @ui.Button::new
  let btn_hyper_stat_close = @ui.MapleButton::from_resource(
      main["BtHyperStatClose"],
    )
    |> @ui.Button::new() // TODO
  let btn_detail_open = @ui.MapleButton::from_resource(main["BtDetailOpen"])
    |> @ui.Button::new() // TODO
  let btn_detail_close = @ui.MapleButton::from_resource(main["BtDetailClose"])
    |> @ui.Button::new() // TODO
  let btn_ability = @ui.MapleButton::from_resource(
      detail["BtAbility"],
      pos=@struct.Point::new(212, 0),
    )
    |> @ui.Button::new
  let btn_detail_detail_close = @ui.MapleButton::from_resource(
      detail["BtHpUp"],
      pos=@struct.Point::new(212, 0),
    )
    |> @ui.Button::new() // TODO
  btn_hyper_stat_open.object.get_button_base().set_active(false)
  btn_detail_close.object.get_button_base().set_active(false)
  btn_ability.object.get_button_base().set_active(false)
  btn_ability.object.get_button_base().set_state(@ui.ButtonState::DISABLED)
  btn_detail_detail_close.object.get_button_base().set_active(false)
  let has_ap = update_ap(stats, [
    btn_hp, btn_mp, btn_str, btn_dex, btn_int, btn_luk, btn_auto,
  ])
  // Normal stat labels
  let name_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 26),
  )
  let job_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 44),
  )
  let guild_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 63),
  )
  let fame_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 80),
  )
  let damage_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 98),
  )
  let hp_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 116),
  )
  let mp_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(74, 134),
  )
  let ap_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(91, 175),
  )
  let str_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 204),
  )
  let dex_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 222),
  )
  let int_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 240),
  )
  let luk_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 258),
  )

  // Detailed stat labels
  let damage_detailed_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 38),
  )
  let damage_bonus_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(100, 56),
  )
  let final_damage_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(100, 74),
  )
  let ignore_defense_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(196, 74),
  )
  let critical_rate_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(100, 92),
  )
  let critical_damage_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 110),
  )
  let knockback_resistance_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(196, 128),
  )
  let defense_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::LEFT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(73, 146),
  )
  let speed_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(100, 164),
  )
  let jump_label = (
    @graphics.Text::new(
      @graphics.FontId::A11M,
      @graphics.TextAlignment::RIGHT,
      @struct.ColorName::EMPEROR,
    ),
    @struct.Point::new(196, 164),
  )
  let ui = {
    model,
    stats,
    btn_close,
    btn_hp,
    btn_mp,
    btn_str,
    btn_dex,
    btn_int,
    btn_luk,
    btn_auto,
    btn_hyper_stat_open,
    btn_hyper_stat_close,
    btn_detail_open,
    btn_detail_close,
    btn_ability,
    btn_detail_detail_close,
    sprites,
    none_ability,
    inner_ability,
    textures_detail,
    show_detail: false,
    has_ap,
    name_label,
    job_label,
    guild_label,
    fame_label,
    damage_label,
    hp_label,
    mp_label,
    ap_label,
    str_label,
    dex_label,
    int_label,
    luk_label,
    damage_detailed_label,
    damage_bonus_label,
    final_damage_label,
    ignore_defense_label,
    critical_rate_label,
    critical_damage_label,
    knockback_resistance_label,
    defense_label,
    speed_label,
    jump_label,
  }
  update_all_stats(ui)
  ui
}

///|
impl @ui.UIElement for UIStatsInfo with render(self) -> @ui.RenderSpec {
  let detailed_labels = if self.show_detail {
    [
      self.damage_detailed_label,
      self.damage_bonus_label,
      self.final_damage_label,
      self.ignore_defense_label,
      self.critical_rate_label,
      self.critical_damage_label,
      self.knockback_resistance_label,
      self.defense_label,
      self.speed_label,
      self.jump_label,
    ]
  } else {
    []
  }
  let normal_labels = [
    self.name_label,
    self.job_label,
    self.guild_label,
    self.fame_label,
    self.damage_label,
    self.hp_label,
    self.mp_label,
    self.ap_label,
    self.str_label,
    self.dex_label,
    self.int_label,
    self.luk_label,
  ]
  let buttons = get_all_buttons(self)
  let details = if self.show_detail {
    let detail_pos = @struct.Point::new(212, 0)
    [
      @ui.StaticUI::new(
        @ui.TextureUI(self.textures_detail[0]),
        pos=detail_pos + @struct.Point::new(0, -1),
      ),
      @ui.StaticUI::new(@ui.TextureUI(self.textures_detail[1]), pos=detail_pos),
      @ui.StaticUI::new(@ui.TextureUI(self.textures_detail[2]), pos=detail_pos),
      @ui.StaticUI::new(@ui.TextureUI(self.textures_detail[3]), pos=detail_pos),
      @ui.StaticUI::new(@ui.TextureUI(self.none_ability), pos=detail_pos),
      @ui.StaticUI::new(
        @ui.TextureUI(self.inner_ability[false]),
        pos=detail_pos,
      ),
      @ui.StaticUI::new(
        @ui.TextureUI(self.inner_ability[false]),
        pos=detail_pos + @struct.Point::new(0, 19),
      ),
      @ui.StaticUI::new(
        @ui.TextureUI(self.inner_ability[false]),
        pos=detail_pos + @struct.Point::new(0, 38),
      ),
    ]
  } else {
    []
  }
  {
    render_units: self.sprites
    .iter()
    .map(fn(sprite) { @ui.SpriteUI(sprite) as &@ui.RenderUnit })
    .concat(details.iter().map(fn(sprite) { sprite as &@ui.RenderUnit }))
    .concat(
      normal_labels
      .iter()
      .map(fn(label) { @ui.StaticUI::new(@ui.TextUI(label._.0), pos=label._.1) }),
    )
    .concat(
      detailed_labels
      .iter()
      .map(fn(label) {
        @ui.StaticUI::new(@ui.TextUI(label._.0), pos=label._.1.shift_x(213))
      }),
    )
    .concat(buttons.iter().map(fn(button) { button as &@ui.RenderUnit }))
    .to_array(),
  }
}

///|
fn get_all_buttons(self : UIStatsInfo) -> Array[@ui.Button] {
  [
    self.btn_close,
    self.btn_hp,
    self.btn_mp,
    self.btn_str,
    self.btn_dex,
    self.btn_int,
    self.btn_luk,
    self.btn_auto,
    self.btn_hyper_stat_open,
    self.btn_hyper_stat_close,
    self.btn_detail_open,
    self.btn_detail_close,
    self.btn_ability,
    self.btn_detail_detail_close,
  ]
}

///|
fn new_spend_ap_packet(stat : @maple_stat.Id) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_AP)
  ..write_time()
  ..write_int(stat.int_value())
}

///|
fn update_ap(stats : CharStats, buttons : Array[@ui.Button]) -> Bool {
  let nowap = stats.get_stat(@maple_stat.Id::AP) > 0
  let newstate = if nowap {
    @ui.ButtonState::NORMAL
  } else {
    @ui.ButtonState::DISABLED
  }
  for button in buttons {
    button.object.get_button_base().set_state(newstate)
  }
  nowap
}

///|
fn update_basevstotal(
  stats : CharStats,
  label : StatLabel,
  base : Int,
  tstat : @equip_stat.Id
) -> Unit {
  let total = stats.get_total(tstat)
  let delta = total - base
  let mut stattext = total.to_string()
  if delta != 0 {
    stattext += " (" + base.to_string()
    if delta > 0 {
      stattext += "+" + delta.to_string()
    } else if delta < 0 {
      stattext += "-" + (-delta).to_string()
    }
    stattext += ")"
  }
  label._.0.change_text(stattext)
}

///|
fn update_buffed(
  stats : CharStats,
  label : StatLabel,
  stat : @equip_stat.Id
) -> Unit {
  let total = stats.get_total(stat)
  let delta = stats.get_buffdelta(stat)
  let mut stattext = total.to_string()
  if delta != 0 {
    stattext += " (" + (total - delta).to_string()
    if delta > 0 {
      stattext += "+" + delta.to_string()
      label._.0.change_color(@struct.ColorName::RED)
    } else if delta < 0 {
      stattext += "-" + (-delta).to_string()
      label._.0.change_color(@struct.ColorName::BLUE)
    }
    stattext += ")"
  }
  label._.0.change_text(stattext)
}

///|
fn update_all_stats(self : UIStatsInfo) -> Unit {
  self.ap_label._.0.change_text(
    self.stats.get_stat(@maple_stat.Id::AP).to_string(),
  )
  if self.has_ap != (self.stats.get_stat(@maple_stat.Id::AP) > 0) {
    self.has_ap = update_ap(self.stats, [
      self.btn_hp,
      self.btn_mp,
      self.btn_str,
      self.btn_dex,
      self.btn_int,
      self.btn_luk,
      self.btn_auto,
    ])
  }
  self.name_label._.0.change_text(self.stats.name)
  self.guild_label._.0.change_text("-")
  self.hp_label._.0.change_text(
    self.stats.get_stat(@maple_stat.Id::HP).to_string() +
    " / " +
    self.stats.get_total(@equip_stat.Id::HP).to_string(),
  )
  self.mp_label._.0.change_text(
    self.stats.get_stat(@maple_stat.Id::MP).to_string() +
    " / " +
    self.stats.get_total(@equip_stat.Id::MP).to_string(),
  )
  update_basevstotal(
    self.stats,
    self.str_label,
    self.stats.get_stat(@maple_stat.Id::STR),
    @equip_stat.Id::STR,
  )
  update_basevstotal(
    self.stats,
    self.dex_label,
    self.stats.get_stat(@maple_stat.Id::DEX),
    @equip_stat.Id::DEX,
  )
  update_basevstotal(
    self.stats,
    self.int_label,
    self.stats.get_stat(@maple_stat.Id::INT),
    @equip_stat.Id::INT,
  )
  update_basevstotal(
    self.stats,
    self.luk_label,
    self.stats.get_stat(@maple_stat.Id::LUK),
    @equip_stat.Id::LUK,
  )
  self.damage_label._.0.change_text(
    self.stats.get_mindamage().to_string() +
    " ~ " +
    self.stats.get_maxdamage().to_string(),
  )
  if self.stats.is_damage_buffed() {
    self.damage_label._.0.change_color(@struct.ColorName::RED)
  } else {
    self.damage_label._.0.change_color(@struct.ColorName::EMPEROR)
  }
  self.damage_detailed_label._.0.change_text(
    self.stats.get_mindamage().to_string() +
    " ~ " +
    self.stats.get_maxdamage().to_string(),
  )
  self.damage_bonus_label._.0.change_text("0%")
  self.final_damage_label._.0.change_text("0%")
  self.ignore_defense_label._.0.change_text(
    self.stats.get_ignoredef().to_int().to_string() + "%",
  )
  self.critical_rate_label._.0.change_text(
    (self.stats.get_critical() * 100).to_int().to_string() + "%",
  )
  self.critical_damage_label._.0.change_text("0.00%")
  self.knockback_resistance_label._.0.change_text("0%")
  update_buffed(self.stats, self.defense_label, @equip_stat.Id::WDEF)
  self.speed_label._.0.change_text(
    self.stats.get_total(@equip_stat.Id::SPEED).to_string() + "%",
  )
  self.jump_label._.0.change_text(
    self.stats.get_total(@equip_stat.Id::JUMP).to_string() + "%",
  )
}

///|
pub fn get_ui_model(self : UIStatsInfo) -> @ui.UIModel {
  self.model
}

///|
pub fn send_cursor(
  self : UIStatsInfo,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  @ui.send_cursor_to_btns(
    get_all_buttons(self).iter(),
    self.model.position,
    pressed,
    cursorpos,
  )
}

///|
pub fn send_key(
  self : UIStatsInfo,
  _keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  if pressed && escape {
    self.model.deactivate()
  }
}

///|
pub fn remove_cursor(self : UIStatsInfo) -> Unit {
  @ui.remove_cursor(
    self.get_all_buttons().iter().map(fn(b) { b.object.get_button_base() }),
  )
}

///|
type StatLabel (@graphics.Text, @struct.Point[Int])
