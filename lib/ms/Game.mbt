// struct Resources {
//   cursor_animations : @immut/hashmap.Map[State, AnimationResource]
// }

type Gl_g

fn draw(
  self : Gl_g,
  bitmap : Bitmap,
  // rect : Rectangle,
  rect_left : Int,
  rect_top : Int,
  rect_right : Int,
  rect_bottom : Int,
  // color : Color,
  color_r : Double,
  color_g : Double,
  color_b : Double,
  color_a : Double,
  angle : Double
) = "gl" "draw"

pub struct Game {
  config : Configuration
  timer : Timer
  stage : Stage
  ui : UI
  mut accumulator : Int
}

pub fn Game::start(g : Gl_g, nowMicro : Int64) -> Game {
  let c = Configuration::default()
  c.set_hardware_info()
  let timer = Timer::new()
  timer.start(nowMicro)
  let animations : Array[(State, Animation)] = []
  {
    config: c,
    timer,
    stage: Stage::default(),
    ui: { cursor: Cursor::new(@immut/hashmap.from_array(animations)) },
    accumulator: 0,
  }
}

pub fn stop(self : Game, nowMicro : Int64) -> Unit {
  // Sound::close();
}

pub fn update_many(self : Game, g : Gl_g, nowMicro : Int64) -> Unit {
  // const int64_t timestep = Constants::TIMESTEP * 1000;
  let timestep = @Constants.timestep * 1000
  // int64_t elapsed = Timer::get().stop();
  let elapsed = self.timer.stop(nowMicro).to_int()

  // Update game with constant timestep as many times as possible.
  // for (accumulator += elapsed; accumulator >= timestep;
  //      accumulator -= timestep) {
  //     update();
  // }
  self.accumulator += elapsed
  while self.accumulator >= timestep {
    self.update()
    self.accumulator -= timestep
  }

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(g, alpha)
}

pub fn update(self : Game) -> Unit {
  // Window::get().check_events();
  // Window::get().update();
  // Stage::get().update();
  // UI::get().update();
  // PacketProcessor::get().process();
  // Music::update_context();
}

pub fn draw(self : Game, g : Gl_g, alpha : Double) -> Unit {
  // Window::get().begin();
  self.stage.draw(g, alpha)
  self.ui.draw(g, alpha)
  // Window::get().end();
}

// fn reset(self : Game, g : Gl_g) -> Result[Unit, String] {
// if (Error error = PacketProcessor::get().init(pApp)) {
//     return error;
// }
// std::cout << "Session init success." << std::endl;

// if (Error error = Window::get().init(pApp)) {
//     return error;
// }
// std::cout << "Window init success." << std::endl;
// if (Error error = Music::init()) {
//     return error;
// }
// std::cout << "Music init success." << std::endl;
// if (Error error = Sound::init()) {
//     return error;
// }
// std::cout << "Sound init success." << std::endl;

// return Error::NONE;
// Ok(())
// }
