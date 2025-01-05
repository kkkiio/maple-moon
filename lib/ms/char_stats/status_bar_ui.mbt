///|
struct UIStatusBar {
  stats : CharStats
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
pub fn UIStatusBar::new(stats : CharStats, hooks : @ui.Hooks) -> UIStatusBar {
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
      state_args=@graphics.DrawArgument::new(pos=exp_pos),
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
        pos=hpmp_pos - @struct.Point::new(1, 0),
      ),
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:cover"],
      state_args=@graphics.DrawArgument::new(
        pos=hpmp_pos - @struct.Point::new(1, 0),
      ),
    ),
  )
  hpmp_sprites.push(
    @graphics.Sprite::from_resource(
      status["layer:Lv"],
      state_args=@graphics.DrawArgument::new(
        pos=hpmp_pos - @struct.Point::new(1, 0),
      ),
    ),
  )
  let hpmp_max = 139 + 30
  let hp_bar = @ui.Gauge::new(
    @ui.GaugeType::GAME,
    status["gauge"]["hp"]["layer:0"] |> @graphics.Texture::from_resource,
    hpmp_max,
    0.0,
  )
  let mp_bar = @ui.Gauge::new(
    @ui.GaugeType::GAME,
    status["gauge"]["mp"]["layer:0"] |> @graphics.Texture::from_resource,
    hpmp_max,
    0.0,
  )
  let stat_set = @graphics.Charset::new(
    expBar["number"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let hpmp_set = @graphics.Charset::new(
    status["gauge"]["number"],
    @graphics.CharsetAlignment::RIGHT,
  )
  let level_set = @graphics.Charset::new(
    status["lvNumber"],
    @graphics.CharsetAlignment::LEFT,
  )
  let position = @struct.Point::new(0, 648)
  let position_x = 585
  let dimension = @struct.Point::new(vwidth - position_x, 75)
  stats.watch_i64stat_changes(@maple_stat.Id::EXP, trigger_now=true, fn(_, _) {
    exp_bar.set_target(getexppercent(stats))
    (hooks.on_state_changed)()
    IterContinue
  })
  stats.watch_stat_changes(@maple_stat.Id::HP, trigger_now=true, fn(_, _) {
    hp_bar.set_target(gethppercent(stats))
    (hooks.on_state_changed)()
    IterContinue
  })
  stats.watch_stat_changes(@maple_stat.Id::MP, trigger_now=true, fn(_, _) {
    mp_bar.set_target(getmppercent(stats))
    (hooks.on_state_changed)()
    IterContinue
  })
  {
    stats,
    base: @ui.UIModel::new(position, dimension),
    sprites,
    exp_bar,
    hp_bar,
    mp_bar,
    stat_set,
    hpmp_set,
    level_set,
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
pub impl @ui.UIElement for UIStatusBar with render(self) {
  let render_units : Array[&@ui.RenderUnit] = Array::new()
  // Add background sprites
  self.sprites
  .iter()
  .each(fn(sprite) { render_units.push(@ui.SpriteUI(sprite)) })
  // Add HP/MP background sprite
  render_units.push(@ui.SpriteUI(self.hpmp_sprites[0]))
  // Add exp bar
  render_units.push(@ui.OffsetedUnit((self.exp_bar, self.exp_pos)))
  // Add HP bar
  render_units.push(@ui.OffsetedUnit((self.hp_bar, self.hpmp_pos)))
  // Add MP bar
  render_units.push(@ui.OffsetedUnit((self.mp_bar, self.hpmp_pos)))
  // Add HP/MP cover sprites
  render_units.push(self.hpmp_sprites[1] |> @ui.SpriteUI)
  render_units.push(self.hpmp_sprites[2] |> @ui.SpriteUI)

  // Add exp text
  let exp = self.stats.get_exp()
  let exp_precent = (getexppercent(self.stats) * 10000.0).to_int()
  render_units.push(
    @ui.StaticUI::new(
      @ui.TextureTextUI(
        self.stat_set.create_text(
          "\{exp}[\{exp_precent/100}.\{exp_precent%100}%]",
        ),
      ),
      pos=self.statset_pos,
    ),
  )

  // Add HP text
  let hp = self.stats.get_stat(@maple_stat.Id::HP)
  let maxhp = self.stats.get_total(@equip_stat.Id::HP)
  render_units.push(
    @ui.StaticUI::new(
      @ui.TextureTextUI(self.hpmp_set.create_text("[\{hp}/\{maxhp}]")),
      pos=self.hpset_pos,
    ),
  )

  // Add MP text
  let mp = self.stats.get_stat(@maple_stat.Id::MP)
  let maxmp = self.stats.get_total(@equip_stat.Id::MP)
  render_units.push(
    @ui.StaticUI::new(
      @ui.TextureTextUI(self.hpmp_set.create_text("[\{mp}/\{maxmp}]")),
      pos=self.mpset_pos,
    ),
  )

  // Add level text
  let level = self.stats.get_stat(@maple_stat.Id::LEVEL)
  render_units.push(
    @ui.StaticUI::new(
      @ui.TextureTextUI(self.level_set.create_text(level.to_string())),
      pos=self.levelset_pos,
    ),
  )
  { render_units, }
}

///|
pub fn update(self : UIStatusBar) -> Unit {
  @ui.update_sprites(self.sprites.iter())
  for sprite in self.hpmp_sprites {
    sprite.update() |> ignore
  }
}

///|
fn getexppercent(stats : CharStats) -> Double {
  let level = stats.get_stat(@maple_stat.Id::LEVEL)
  if level >= LEVEL_CAP {
    return 0.0
  }
  let exp = stats.get_exp()
  exp.to_double() / exp_table[level].to_double()
}

///|
fn gethppercent(stats : CharStats) -> Double {
  let hp = stats.get_stat(@maple_stat.Id::HP)
  let maxhp = stats.get_total(@equip_stat.Id::HP)
  hp.to_double() / maxhp.to_double()
}

///|
fn getmppercent(stats : CharStats) -> Double {
  let mp = stats.get_stat(@maple_stat.Id::MP)
  let maxmp = stats.get_total(@equip_stat.Id::MP)
  mp.to_double() / maxmp.to_double()
}

///|
pub fn get_ui_model(self : UIStatusBar) -> @ui.UIModel {
  self.base
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
