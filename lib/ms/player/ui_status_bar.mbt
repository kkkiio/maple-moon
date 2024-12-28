///|
struct UIStatusBar {
  stats : @char_stats.CharStats
  base : @ui.UIModel
  sprites : Array[@graphics.Sprite]
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

///|
pub fn UIStatusBar::new(stats : @char_stats.CharStats) -> UIStatusBar {
  let vwidth = @constants.constants.get_viewwidth()
  let mainBar = @ui.common_ui_loader().load_res(["StatusBar3.img", "mainBar"])
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
      state_args=@graphics.DrawArgument::new(position=exp_pos),
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
      state_args=@graphics.DrawArgument::new(
        position=hpmp_pos - @struct.Point::new(1, 0),
      ),
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:cover"],
      state_args=@graphics.DrawArgument::new(
        position=hpmp_pos - @struct.Point::new(1, 0),
      ),
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:Lv"],
      state_args=@graphics.DrawArgument::new(
        position=hpmp_pos - @struct.Point::new(1, 0),
      ),
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
  stats.listen_stat_changes(@maple_stat.Id::EXP, fn(_old, _new) {
    exp_bar.update(getexppercent(stats))
    true
  })
  stats.listen_stat_changes(@maple_stat.Id::HP, fn(_old, _new) {
    hp_bar_.update(gethppercent(stats))
    true
  })
  stats.listen_stat_changes(@maple_stat.Id::MP, fn(_old, _new) {
    mp_bar_.update(getmppercent(stats))
    true
  })
  {
    stats,
    base: @ui.UIModel::new(position, dimension),
    sprites,
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

///|
pub impl @ui.UIElement for UIStatusBar with render(self) -> @ui.RenderSpec {
  let sprites = self.sprites
  fn draw(alpha : Double) -> Unit {
    @ui.draw_sprites(sprites.iter(), self.base.position, alpha)
    self.hpmp_sprites[0].draw(self.base.position, alpha)
    self.exp_bar.draw(
      @graphics.DrawArgument::new(position=self.base.position + self.exp_pos),
    )
    self.hp_bar.draw(
      @graphics.DrawArgument::new(position=self.base.position + self.hpmp_pos),
    )
    self.mp_bar.draw(
      @graphics.DrawArgument::new(position=self.base.position + self.hpmp_pos),
    )
    self.hpmp_sprites[1].draw(self.base.position, alpha)
    self.hpmp_sprites[2].draw(self.base.position, alpha)
    let exp = self.stats.get_exp()
    let exp_precent = (getexppercent(self.stats) * 10000.0).to_int()
    self.stat_set.draw_text(
      "\{exp}[\{exp_precent/100}.\{exp_precent%100}%]",
      @graphics.DrawArgument::new(
        position=self.base.position + self.statset_pos,
      ),
    )
    |> ignore
    let hp = self.stats.get_stat(@maple_stat.Id::HP)
    let maxhp = self.stats.get_total(@stat.Id::HP)
    self.hpmp_set.draw_text(
      "[\{hp}/\{maxhp}]",
      @graphics.DrawArgument::new(position=self.base.position + self.hpset_pos),
    )
    |> ignore
    let mp = self.stats.get_stat(@maple_stat.Id::MP)
    let maxmp = self.stats.get_total(@stat.Id::MP)
    self.hpmp_set.draw_text(
      "[\{mp}/\{maxmp}]",
      @graphics.DrawArgument::new(position=self.base.position + self.mpset_pos),
    )
    |> ignore
    let level = self.stats.get_stat(@maple_stat.Id::LEVEL)
    self.level_set.draw_text(
      level.to_string(),
      @graphics.DrawArgument::new(
        position=self.base.position + self.levelset_pos,
      ),
    )
    |> ignore
  }

  { sprites, buttons: [], drawables: [] }
} // TODO

///|
pub fn update(self : UIStatusBar) -> Unit {
  @ui.update_sprites(self.sprites.iter())
  for sprite in self.hpmp_sprites {
    sprite.update() |> ignore
  }
}

///|
fn getexppercent(stats : @char_stats.CharStats) -> Double {
  let level = stats.get_stat(@maple_stat.Id::LEVEL)
  if level >= @character.level_cap {
    return 0.0
  }
  let exp = stats.get_exp()
  exp.to_double() / @character.exp_table[level].to_double()
}

///|
fn gethppercent(stats : @char_stats.CharStats) -> Double {
  let hp = stats.get_stat(@maple_stat.Id::HP)
  let maxhp = stats.get_total(@stat.Id::HP)
  hp.to_double() / maxhp.to_double()
}

///|
fn getmppercent(stats : @char_stats.CharStats) -> Double {
  let mp = stats.get_stat(@maple_stat.Id::MP)
  let maxmp = stats.get_total(@stat.Id::MP)
  mp.to_double() / maxmp.to_double()
}

///|
pub fn get_ui_model(self : UIStatusBar) -> @ui.UIModel {
  self.base
}

///|
pub fn send_cursor(
  self : UIStatusBar,
  pressed : Bool,
  _cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  if pressed {
    @ui.CursorState::CLICKING
  } else {
    @ui.CursorState::IDLE
  }
}

///|
pub fn send_key(
  self : UIStatusBar,
  keycode : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  // TODO: implement
}

///|
pub fn remove_cursor(self : UIStatusBar) -> Unit {
  // TODO: implement
}
