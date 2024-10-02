struct UIStatusBar {
  stats : @character.CharStats
  base : @ui.UIElementBase
  ui_buttons : @ui.UIButtons
  exp_bar : @ui.Gauge
  hp_bar : @ui.Gauge
  mp_bar : @ui.Gauge
  stat_set : @graphics.Charset
  hpmp_set : @graphics.Charset
  level_set : @graphics.Charset
  hpmp_sprites : Array[@graphics.Sprite]
  exp_pos : @struct.Point[Int]
  hpmp_pos : @struct.Point[Int]
  hpset_pos : @struct.Point[Int]
  mpset_pos : @struct.Point[Int]
  statset_pos : @struct.Point[Int]
  levelset_pos : @struct.Point[Int]
}

pub fn UIStatusBar::new(stats : @character.CharStats) -> UIStatusBar {
  let vwidth = @constants.constants.get_viewwidth()
  let mainBar = @resource.ui_loader().load_res(["StatusBar3.img", "mainBar"])
  let stat = "status"
  let status = mainBar[stat]
  let expBar = mainBar["EXPBar"]
  let expBarRes = expBar[vwidth.to_string()]
  let exp_pos = @struct.Point::new(0, 87)
  let sprites = Array::new()
  sprites.push(
    @graphics.Sprite::from_resource(
      expBar["backgrnd"],
      state_args=@graphics.DrawArgument::new4(
        @struct.Point::new(0, 87),
        @struct.Point::new(vwidth, 0),
      ),
    ),
  )
  sprites.push(
    @graphics.Sprite::from_resource(
      expBarRes["layer:back"],
      state_args=exp_pos |> @graphics.DrawArgument::new,
    ),
  )
  let exp_max = vwidth - 16
  let exp_bar = @ui.Gauge::new_with_mid_end(
    @ui.GaugeType::GAME,
    expBarRes["layer:gauge"] |> @graphics.Texture::from_resource,
    expBarRes["layer:cover"] |> @graphics.Texture::from_resource,
    expBarRes["layer:effect"] |> @graphics.Texture::from_resource,
    exp_max,
    0.0,
  )
  let pos_adj = 171
  let hpmp_pos = @struct.Point::new(416 + pos_adj, 40)
  let hpset_pos = @struct.Point::new(550 + pos_adj, 70)
  let mpset_pos = @struct.Point::new(546 + pos_adj, 86)
  let statset_pos = @struct.Point::new(539 + pos_adj, 111)
  let levelset_pos = @struct.Point::new(465 + pos_adj, 48)
  let hpmp_sprites = Array::new()
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["backgrnd"],
      state_args=hpmp_pos - @struct.Point::new(1, 0)
        |> @graphics.DrawArgument::new,
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:cover"],
      state_args=hpmp_pos - @struct.Point::new(1, 0)
        |> @graphics.DrawArgument::new,
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:Lv"],
      state_args=hpmp_pos - @struct.Point::new(1, 0)
        |> @graphics.DrawArgument::new,
    ),
  )
  let hpmp_max = 139 + 30
  let hp_bar_ = @ui.Gauge::new(
    @ui.GaugeType::GAME,
    status["gauge"]["hp"]["layer:0"] |> @graphics.Texture::from_resource,
    hpmp_max,
    0.0,
  )
  let mp_bar_ = @ui.Gauge::new(
    @ui.GaugeType::GAME,
    status["gauge"]["mp"]["layer:0"] |> @graphics.Texture::from_resource,
    hpmp_max,
    0.0,
  )
  let stat_set_ = @graphics.Charset::new(
    expBar["number"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let hpmp_set_ = @graphics.Charset::new(
    status["gauge"]["number"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let level_set_ = @graphics.Charset::new(
    status["lvNumber"],
    @graphics.CharsetAlignment::LEFT,
  )
  let position = @struct.Point::new(0, 648)
  let position_x = 585
  let dimension = @struct.Point::new(vwidth - position_x, 75)
  {
    stats,
    base: @ui.UIElementBase::new(position, dimension),
    ui_buttons: @ui.UIButtons::default(),
    exp_bar,
    hp_bar: hp_bar_,
    mp_bar: mp_bar_,
    stat_set: stat_set_,
    hpmp_set: hpmp_set_,
    level_set: level_set_,
    hpmp_sprites,
    exp_pos,
    hpmp_pos,
    hpset_pos,
    mpset_pos,
    statset_pos,
    levelset_pos,
  }
}

pub fn draw(self : UIStatusBar, alpha : Double) -> Unit {
  self.base.draw(alpha)
  // for i in 0..=bt_event {
  //   self.ui_buttons.buttons[i].unwrap().draw(self.base.position)
  // }
  self.hpmp_sprites[0].draw(self.base.position, alpha)
  self.exp_bar.draw(
    self.base.position + self.exp_pos |> @graphics.DrawArgument::new,
  )
  self.hp_bar.draw(
    self.base.position + self.hpmp_pos |> @graphics.DrawArgument::new,
  )
  self.mp_bar.draw(
    self.base.position + self.hpmp_pos |> @graphics.DrawArgument::new,
  )
  self.hpmp_sprites[1].draw(self.base.position, alpha)
  self.hpmp_sprites[2].draw(self.base.position, alpha)
  let exp = self.stats.get_exp()
  let exp_precent = (getexppercent(self.stats) * 10000.0).to_int()
  self.stat_set.draw_text(
    "\{exp}[\{exp_precent/100}.\{exp_precent%100}%]",
    self.base.position + self.statset_pos |> @graphics.DrawArgument::new,
  )
  |> ignore
  let hp = self.stats.get_stat(@MapleStat.Id::HP)
  let maxhp = self.stats.get_total(@stat.Id::HP)
  self.hpmp_set.draw_text(
    "[\{hp}/\{maxhp}]",
    self.base.position + self.hpset_pos |> @graphics.DrawArgument::new,
  )
  |> ignore
  let mp = self.stats.get_stat(@MapleStat.Id::MP)
  let maxmp = self.stats.get_total(@stat.Id::MP)
  self.hpmp_set.draw_text(
    "[\{mp}/\{maxmp}]",
    self.base.position + self.mpset_pos |> @graphics.DrawArgument::new,
  )
  |> ignore
  let level = self.stats.get_stat(@MapleStat.Id::LEVEL)
  self.level_set.draw_text(
    level.to_string(),
    self.base.position + self.levelset_pos |> @graphics.DrawArgument::new,
  )
  |> ignore
}

pub fn update(self : UIStatusBar) -> Unit {
  self.base.update()
  for sprite in self.hpmp_sprites {
    sprite.update() |> ignore
  }
  self.exp_bar.update(getexppercent(self.stats))
  self.hp_bar.update(gethppercent(self.stats))
  self.mp_bar.update(getmppercent(self.stats))
}

// let bt_cashshop = 0

// let bt_menu = 1

// let bt_options = 2

// let bt_character = 3

// let bt_community = 4

// let bt_event = 5

// let bt_fold_qs = 6

// let bt_extend_qs = 7

// let bt_menu_quest = 8

// let bt_menu_medal = 9

// let bt_menu_union = 10

// let bt_menu_monster_collection = 11

// let bt_menu_auction = 12

// let bt_menu_monster_life = 13

// let bt_menu_battle = 14

// let bt_menu_achievement = 15

// let bt_menu_fishing = 16

// let bt_menu_help = 17

// let bt_menu_claim = 18

// let bt_setting_channel = 19

// let bt_setting_option = 20

// let bt_setting_keys = 21

// let bt_setting_joypad = 22

// let bt_setting_quit = 23

// let bt_community_friends = 24

// let bt_community_party = 25

// let bt_community_guild = 26

// let bt_community_maplechat = 27

// let bt_character_info = 28

// let bt_character_stat = 29

// let bt_character_skill = 30

// let bt_character_equip = 31

// let bt_character_item = 32

// let bt_event_schedule = 33

// let bt_event_daily = 34

fn getexppercent(stats : @character.CharStats) -> Double {
  let level = stats.get_stat(@MapleStat.Id::LEVEL)
  if level >= @character.level_cap {
    return 0.0
  }
  let exp = stats.get_exp()
  exp.to_double() / @character.exp_table[level].to_double()
}

fn gethppercent(stats : @character.CharStats) -> Double {
  let hp = stats.get_stat(@MapleStat.Id::HP)
  let maxhp = stats.get_total(@stat.Id::HP)
  hp.to_double() / maxhp.to_double()
}

fn getmppercent(stats : @character.CharStats) -> Double {
  let mp = stats.get_stat(@MapleStat.Id::MP)
  let maxmp = stats.get_total(@stat.Id::MP)
  mp.to_double() / maxmp.to_double()
}

pub fn get_ui_element_base(self : UIStatusBar) -> @ui.UIElementBase {
  self.base
}

pub fn send_cursor(
  self : UIStatusBar,
  pressed : Bool,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  self.ui_buttons.send_cursor(
    self.base.position,
    fn(buttonid) { self.button_pressed(buttonid) },
    pressed,
    cursorpos,
  )
}

pub fn button_pressed(self : UIStatusBar, buttonid : Int) -> @ui.ButtonState {
  // TODO: add buttons
  @ui.ButtonState::IDENTITY
}

pub fn send_key(
  self : UIStatusBar,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

pub fn get_type(self : UIStatusBar) -> @ui.UIElementType {
  @ui.UIElementType::STATUS_BAR
}

pub fn is_in_range(self : UIStatusBar, position : @struct.Point[Int]) -> Bool {
  self.base.is_in_range(position)
}

pub fn toggle_active(self : UIStatusBar) -> Unit {
  self.base.toggle_active()
}

pub fn remove_cursor(self : UIStatusBar) -> Unit {
  // TODO: implement
}
