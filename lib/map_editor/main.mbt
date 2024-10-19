struct EntryPoint {
  mut state : State
  down_keys : Map[String, Bool]
  mut speed : Int
}

enum State {
  NONE
  LOADING(~poll_fn : () -> @map.MapStruct?!)
  ACTIVE(~map : @map.MapStruct, mut ~viewpos : @struct.Point[Double])
}

let g_state : EntryPoint = {
  state: State::NONE,
  down_keys: Map::new(),
  speed: 2,
}

pub fn load_map(map_id : Int) -> Unit {
  let poll_fn = @map.load_map(map_id)
  g_state.state = State::LOADING(~poll_fn)
}

pub fn update(_time : Double) -> Unit {
  match g_state.state {
    State::NONE => ()
    State::LOADING(~poll_fn) => {
      guard let Ok(Some(map)) = poll_fn?() else {
        Ok(None) => return
        Err(err) => {
          @log.error({ "err": err }, "Failed to load map")
          g_state.state = State::NONE
          return
        }
      }
      g_state.state = State::ACTIVE(~map, viewpos=@struct.Point::default())
    }
    State::ACTIVE(~map, ~viewpos) as state => {
      let viewpos = update_viewpos(g_state.down_keys, viewpos, g_state.speed)
      state.viewpos = viewpos
      let alpha = 0.0
      @graphics.GraphicsGL::get().clear_scene()
      draw_map(map, viewpos, alpha)
      @graphics.GraphicsGL::get().flush(1.0)
    }
  }
}

pub fn onkeydown(key : String) -> Unit {
  g_state.down_keys.set(key, true)
}

pub fn onkeyup(key : String) -> Unit {
  g_state.down_keys.set(key, false)
}

pub fn set_speed(new_speed : Int) -> Unit {
  g_state.speed = clamp(new_speed, 1, 10)
}

fn draw_map(
  map : @map.MapStruct,
  viewpos : @struct.Point[Double],
  alpha : Double
) -> Unit {
  let backgrounds = map.backgrounds
  let tiles_objs = map.tiles_objs
  let portals = map.portals
  backgrounds.drawbackgrounds(viewpos.x, viewpos.y, alpha)
  let int_viewpos : @struct.Point[Int] = {
    x: viewpos.x.round().to_int(),
    y: viewpos.y.round().to_int(),
  }
  for id in @layer.ids {
    tiles_objs.draw(id, int_viewpos, alpha)
  }
  portals.draw(int_viewpos, alpha)
  backgrounds.drawforegrounds(viewpos.x, viewpos.y, alpha)
}

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

fn clamp[T : Compare](x : T, min : T, max : T) -> T {
  if x < min {
    min
  } else if x > max {
    max
  } else {
    x
  }
}
