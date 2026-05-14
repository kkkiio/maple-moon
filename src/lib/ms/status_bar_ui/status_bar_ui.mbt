///|
priv struct StatusBarState {
  entities : Array[@entity.Entity]
  mut last_snapshot : String
}

///|
let state_ref : Ref[StatusBarState] = Ref({ entities: [], last_snapshot: "" })

///|
const STATUS_BAR_Z : Int = @graphics.UI_ZINDEX + 40

///|
const STATUS_TEXT_COLOR = "#F7F1D5"

///|
const STATUS_FONT = "bold 12px Menlo"

///|
fn clear_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    @text2d.text2ds().remove(entity) |> ignore
    @selene_ui.texts().remove(entity) |> ignore
    @selene_ui.text_fonts().remove(entity) |> ignore
    @selene_ui.text_colors().remove(entity) |> ignore
    @selene_ui.text_layouts().remove(entity) |> ignore
    @transform2d.remove(entity) |> ignore
    entity.destroy()
  }
  entities.clear()
}

///|
fn spawn_text(
  entities : Array[@entity.Entity],
  text : String,
  x : Int,
  y : Int,
  z : Int,
  align? : @selene_math.HAlign = @selene_math.Left,
) -> Unit {
  let entity = @entity.Entity()
  entities.push(entity)
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(x.to_double(), y.to_double(), z.to_double()),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d())
  @selene_ui.texts().set(entity, @selene_ui.Text(text))
  @selene_ui.text_fonts().set(
    entity,
    @selene_ui.TextFont::from_css(STATUS_FONT),
  )
  @selene_ui.text_colors().set(
    entity,
    @selene_ui.TextColor::from_css(STATUS_TEXT_COLOR),
  )
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout(align~, baseline=@selene_math.Top),
  )
}

///|
fn exp_percent_text(stats : @char_stats.CharStats) -> String {
  let level = stats.get_stat(@maple_stat.Id::LEVEL)
  if level >= @char_stats.LEVEL_CAP {
    return "100.00%"
  }
  let exp = stats.get_exp().to_double()
  let need = @char_stats.exp_table[level].to_double()
  let percent = if need <= 0.0 { 0.0 } else { exp * 100.0 / need }
  let percent100 = (percent * 100.0).to_int()
  "\{percent100 / 100}.\{(percent100 % 100).to_string().pad_start(2, '0')}%"
}

///|
fn snapshot_text(stats : @char_stats.CharStats) -> String {
  let hp = stats.get_stat(@maple_stat.Id::HP)
  let max_hp = stats.get_total(@maple_stat.EquipStatId::HP)
  let mp = stats.get_stat(@maple_stat.Id::MP)
  let max_mp = stats.get_total(@maple_stat.EquipStatId::MP)
  let level = stats.get_stat(@maple_stat.Id::LEVEL)
  "LV=\{level};HP=\{hp}/\{max_hp};MP=\{mp}/\{max_mp};EXP=\{stats.get_exp()}"
}

///|
fn rebuild_status_bar(
  state : StatusBarState,
  stats : @char_stats.CharStats,
) -> Unit {
  rebuild_status_bar_lines(state, [
    "LV \{stats.get_stat(@maple_stat.Id::LEVEL)}",
    "HP \{stats.get_stat(@maple_stat.Id::HP)}/\{stats.get_total(@maple_stat.EquipStatId::HP)}",
    "MP \{stats.get_stat(@maple_stat.Id::MP)}/\{stats.get_total(@maple_stat.EquipStatId::MP)}",
    "EXP \{exp_percent_text(stats)}",
  ])
}

///|
fn rebuild_status_bar_lines(
  state : StatusBarState,
  lines : Array[String],
) -> Unit {
  clear_entities(state.entities)
  let right = @graphics.view_size.0 - 18
  let base_y = @graphics.view_size.1 - 84
  // TODO: 旧 StatusBar3 艺术资源尚未迁到新的 selene HUD 方案，当前先显示文本 HUD。
  for i, line in lines {
    spawn_text(
      state.entities,
      line,
      right,
      base_y + i * 18,
      STATUS_BAR_Z,
      align=@selene_math.Right,
    )
  }
}

///|
fn clear_status_bar() -> Unit {
  let state = state_ref.val
  clear_entities(state.entities)
  state.last_snapshot = ""
}

///|
/// Render the in-game status bar HUD with selene text sprites.
pub fn status_bar_ui_system(_world : @ecs.World) -> Unit {
  guard @game_state.current_phase() is @game_state.GamePhase::GameActive(..) else {
    clear_status_bar()
    return
  }
  guard @player.get_player() is Some(player) else {
    clear_status_bar()
    return
  }
  let state = state_ref.val
  let stats = player.get_stats()
  let snapshot = snapshot_text(stats)
  if snapshot == state.last_snapshot {
    return
  }
  state.last_snapshot = snapshot
  rebuild_status_bar(state, stats)
}
