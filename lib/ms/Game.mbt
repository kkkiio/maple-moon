pub struct Game {
  config : Configuration
  mut accumulator : Int
}

pub fn Game::start() -> Game {
  let c = Configuration::default()
  c.set_hardware_info()
  @net.PacketProcessor::get().initialize()
  timer.start()
  map_portals_animations.load()
  { config: c, accumulator: 0 }
}

pub fn stop(self : Game) -> Unit {
  // Sound::close();
}

pub fn on_draw(self : Game, time : TimePoint) -> Unit {
  let timestep = @Constants.timestep * 1000
  let elapsed = Timer::get().stop(time)

  // Update game with constant timestep as many times as possible.
  self.accumulator += elapsed.to_micro_seconds()
  let times = self.accumulator / timestep
  self.accumulator -= timestep * times
  (0).until(times).each(fn(_i) { self.update() })

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(alpha)
}

pub fn update(self : Game) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  Stage::get().update()
  UI::get().update()
  @net.PacketProcessor::get().process_in()
  // Music::update_context();
}

pub fn draw(self : Game, alpha : Double) -> Unit {
  Window::get().begin()
  Stage::get().draw(alpha)
  UI::get().draw(alpha)
  Window::get().end()
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
