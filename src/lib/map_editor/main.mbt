///|
priv struct EntryPoint {
  mut state : State
  down_keys : Map[String, Bool]
  mut speed : Int
  mut draw_tiles : Bool
}

///|
priv enum State {
  NONE
  LOADING(loading_map~ : @utils.Future[Result[@map.SceneMap, Error]])
  ACTIVE(
    map~ : @map.SceneMap,
    mut viewpos~ : @struct.Point[Double],
    hide_backgrounds~ : Map[Int, Bool],
    hide_foregrounds~ : Map[Int, Bool]
  )
}

///|
let g_state : EntryPoint = {
  state: State::NONE,
  down_keys: Map::new(),
  speed: 5,
  draw_tiles: true,
}

///|
pub fn load_map(map_id : Int) -> Unit {
  let loading_map = @map.MapPortalAnimations::load().bind(fn(
    map_portals_animations
  ) {
    @map.load_map(map_id, map_portals_animations)
  })
  g_state.state = State::LOADING(loading_map~)
}

///|
pub fn update(_time : Double) -> Unit {
  match g_state.state {
    State::NONE => ()
    State::LOADING(loading_map~) =>
      match loading_map.poll() {
        Some(Ok(map)) =>
          g_state.state = State::ACTIVE(
            map~,
            viewpos=@struct.Point::default(),
            hide_backgrounds=Map::new(),
            hide_foregrounds=Map::new(),
          )
        None => return
        Some(Err(err)) => {
          @log.error({ "err": err }, "Failed to load map")
          g_state.state = State::NONE
          return
        }
      }
    State::ACTIVE(map~, viewpos~, hide_backgrounds~, hide_foregrounds~) as state => {
      let viewpos = update_viewpos(g_state.down_keys, viewpos, g_state.speed)
      state.viewpos = viewpos
      on_view_position_change(viewpos.x, viewpos.y)
      let alpha = 0.0
      @graphics.GraphicsGL::get().clear_scene()
      update_map(map.backgrounds, map.tiles_objs, map.portals)
      draw_map(map, viewpos, hide_backgrounds, hide_foregrounds, alpha)
      @graphics.GraphicsGL::get().flush(1.0)
    }
  }
}

///|
pub fn onkeydown(key : String) -> Unit {
  g_state.down_keys.set(key, true)
}

///|
pub fn onkeyup(key : String) -> Unit {
  g_state.down_keys.set(key, false)
}

///|
pub fn set_speed(new_speed : Int) -> Unit {
  g_state.speed = clamp(new_speed, 1, 10)
}

///|
pub fn set_draw_tiles(draw_tiles : Bool) -> Unit {
  g_state.draw_tiles = draw_tiles
}

///|
pub fn is_loaded() -> Bool {
  match g_state.state {
    State::ACTIVE(..) => true
    _ => false
  }
}

///|
pub fn get_background_count() -> Int {
  match g_state.state {
    State::ACTIVE(map~, ..) => map.backgrounds.backs.length()
    _ => 0
  }
}

///|
pub fn get_foreground_count() -> Int {
  match g_state.state {
    State::ACTIVE(map~, ..) => map.backgrounds.fores.length()
    _ => 0
  }
}

///|
pub fn set_show_background(index : Int, show_background : Bool) -> Unit {
  guard g_state.state is State::ACTIVE(hide_backgrounds~, ..) else { return }
  hide_backgrounds.set(index, not(show_background))
}

///|
pub fn set_show_foreground(index : Int, show_foreground : Bool) -> Unit {
  guard g_state.state is State::ACTIVE(hide_foregrounds~, ..) else { return }
  hide_foregrounds.set(index, not(show_foreground))
}

///|
fn draw_map(
  map : @map.SceneMap,
  viewpos : @struct.Point[Double],
  hide_backgrounds : Map[Int, Bool],
  hide_foregrounds : Map[Int, Bool],
  alpha : Double
) -> Unit {
  let backgrounds = map.backgrounds
  let tiles_objs = map.tiles_objs
  let portals = map.portals
  for i, background in backgrounds.backs {
    if hide_backgrounds.get_or_default(i, false) {
      continue
    }
    background.draw(viewpos.x, viewpos.y, alpha)
  }
  let int_viewpos : @struct.Point[Int] = {
    x: viewpos.x.round().to_int(),
    y: viewpos.y.round().to_int(),
  }
  if g_state.draw_tiles {
    for id in @map_layer.ids {
      tiles_objs.draw(id, int_viewpos, alpha)
    }
  }
  portals.draw(int_viewpos, alpha)
  for i, background in backgrounds.fores {
    if hide_foregrounds.get_or_default(i, false) {
      continue
    }
    background.draw(viewpos.x, viewpos.y, alpha)
  }
}

///|
fn update_map(
  backgrounds : @map.Backgrounds,
  tiles_objs : @map.MapTilesObjs,
  portals : @map.MapPortals
) -> Unit {
  @map.update_backgrounds(backgrounds)
  tiles_objs.update()
  portals.update(@struct.Point::default()) // TODO: add player
}

///|
fn update_viewpos(
  down_keys : Map[String, Bool],
  viewpos : @struct.Point[Double],
  speed : Int
) -> @struct.Point[Double] {
  let mut viewpos = viewpos
  let speed_f = speed.to_double()
  if down_keys.get_or_default(@keyboard.arrowLeft, false) {
    viewpos = viewpos.shift_x(speed_f)
  }
  if down_keys.get_or_default(@keyboard.arrowRight, false) {
    viewpos = viewpos.shift_x(-speed_f)
  }
  if down_keys.get_or_default(@keyboard.arrowUp, false) {
    viewpos = viewpos.shift_y(speed_f)
  }
  if down_keys.get_or_default(@keyboard.arrowDown, false) {
    viewpos = viewpos.shift_y(-speed_f)
  }
  viewpos
}

///|
fn clamp[T : Compare](x : T, min : T, max : T) -> T {
  if x < min {
    min
  } else if x > max {
    max
  } else {
    x
  }
}

///|
fn on_view_position_change(x : Double, y : Double) = "map_editor" "on_view_position_change"
