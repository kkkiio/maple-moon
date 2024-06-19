// app/src/main/cpp/src/Graphics/Animation.h
// app/src/main/cpp/src/Graphics/Animation.cpp
struct Frame {
  texture : Texture
  delay : Int
  bounds : Rectangle[Int]
  head : Point[Int]
  opacities : (Int, Int)
  scales : (Int, Int)
}

fn Frame::from_resource(src : NxNode) -> Frame {
  let texture = Texture::from_resource(src)
  let bounds = Rectangle::from_resource(src)
  let head = Point::from_resource(src["head"])
  let delay = match src["delay"].get_int() {
    0 => 100
    it => it
  }
  let opacities = match (src["a0"].desc, src["a1"].desc) {
    (@json.JsonValue::Number(a0), @json.JsonValue::Number(a1)) =>
      (a0.to_int(), a1.to_int())
    (@json.JsonValue::Number(a0), _) => (a0.to_int(), 255 - a0.to_int())
    (_, @json.JsonValue::Number(a1)) => (255 - a1.to_int(), a1.to_int())
    _ => (255, 255)
  }
  let scales = match (src["z0"].desc, src["z1"].desc) {
    (@json.JsonValue::Number(z0), @json.JsonValue::Number(z1)) =>
      (z0.to_int(), z1.to_int())
    (@json.JsonValue::Number(z0), _) => (z0.to_int(), 0)
    (_, @json.JsonValue::Number(z1)) => (100, z1.to_int())
    _ => (100, 100)
  }
  { texture, delay, head, bounds, opacities, scales }
}

fn Frame::default() -> Frame {
  {
    texture: Texture::default(),
    head: Point::default(),
    bounds: Rectangle::default(),
    delay: 0,
    opacities: (0, 0),
    scales: (0, 0),
  }
}

pub fn start_opacity(self : Frame) -> Int {
  self.opacities.0
}

pub fn start_scale(self : Frame) -> Int {
  self.scales.0
}

pub fn get_delay(self : Frame) -> Int {
  self.delay
}

pub fn get_origin(self : Frame) -> Point[Int] {
  self.texture.origin
}

pub fn get_dimensions(self : Frame) -> Point[Int] {
  self.texture.dimensions
}

pub fn get_head(self : Frame) -> Point[Int] {
  self.head
}

pub fn get_bounds(self : Frame) -> Rectangle[Int] {
  self.bounds
}

pub fn opcstep(self : Frame, timestep : Int) -> Double {
  timestep.to_double() * (self.opacities.1 - self.opacities.0).to_double() / self.delay.to_double()
}

pub fn scalestep(self : Frame, timestep : Int) -> Double {
  timestep.to_double() * (self.scales.1 - self.scales.0).to_double() / self.delay.to_double()
}

pub fn draw(self : Frame, args : DrawArgument) -> Unit {
  self.texture.draw(args)
}

// Class which consists of multiple textures to make an Animation.
struct Animation {
  frames : FixedArray[Frame]
  zigzag : Bool
  frame : Nominal[Int]
  mut opacity : Linear
  mut xyscale : Linear
  mut frame_step : Int
  mut delay : Int
}

pub fn Animation::from_resource(src : NxNode) -> Animation {
  let frames = match src.desc.as_object() {
    Some(obj) =>
      if obj.contains("__b") {
        FixedArray::[Frame::from_resource(src)]
      } else {
        let fs = obj.as_iter().filter(
            fn(it) { @strconv.parse_int(it.0).is_ok() },
          ).map(fn(it) { Frame::from_resource(src[it.0]) }).collect()
          |> to_fixarray
        if fs.length() <= 0 {
          debug(obj)
          abort("Animation must have at least one frame.")
        }
        fs
      }
    None => [Frame::default()]
  }
  let zigzag = src["zigzag"].get_bool()
  let a = {
    frames,
    zigzag,
    frame: Nominal::default(),
    opacity: Linear::default(),
    xyscale: Linear::default(),
    frame_step: 0,
    delay: 0,
  }
  a.reset()
  a
}

pub fn Animation::default() -> Animation {
  let a = {
    frames: [Frame::default()],
    zigzag: false,
    frame: Nominal::default(),
    opacity: Linear::default(),
    xyscale: Linear::default(),
    frame_step: 0,
    delay: 0,
  }
  a.reset()
  a
}

pub fn draw(self : Animation, args : DrawArgument, alpha : Double) -> Unit {
  let interframe = self.frame.get(alpha)
  let interopc = self.opacity.get(alpha) / 255.0
  let interscale = self.xyscale.get(alpha) / 100.0
  let modifyopc = interopc != 1.0
  let modifyscale = interscale != 1.0
  if modifyopc || modifyscale {
    self.frames[interframe].draw(
      args + DrawArgument::new12(interscale, interscale, interopc),
    )
  } else {
    self.frames[interframe].draw(args)
  }
}

pub fn update(self : Animation, ~timestep : Int = @Constants.timestep) -> Bool {
  let framedata = self.get_frame()
  self.opacity.add(framedata.opcstep(timestep))
  if self.opacity.last() < 0.0 {
    self.opacity.set(0.0)
  } else if self.opacity.last() > 255.0 {
    self.opacity.set(255.0)
  }
  self.xyscale.add(framedata.scalestep(timestep))
  if self.xyscale.last() < 0.0 {
    self.xyscale.set(0.0)
  }
  if timestep >= self.delay {
    let lastframe = self.frames.length() - 1
    let mut nextframe = 0
    let mut ended = false
    if self.zigzag && lastframe > 0 {
      if self.frame_step == 1 && self.frame.now == lastframe {
        self.frame_step = -self.frame_step
        ended = false
      } else if self.frame_step == -1 && self.frame.now == 0 {
        self.frame_step = -self.frame_step
        ended = true
      }
      nextframe = self.frame.now + self.frame_step
    } else if self.frame.now == lastframe {
      nextframe = 0
      ended = true
    } else {
      nextframe = self.frame.now + 1
      ended = false
    }
    let delta = timestep - self.delay
    let threshold = delta.to_double() / timestep.to_double()
    self.frame.next(nextframe, threshold)
    self.delay = self.frames[nextframe].get_delay()
    if self.delay >= delta {
      self.delay -= delta
    }
    self.opacity.set(self.frames[nextframe].start_opacity().to_double())
    self.xyscale.set(self.frames[nextframe].start_scale().to_double())
    return ended
  }
  self.frame.normalize()
  self.delay -= timestep
  false
}

pub fn reset(self : Animation) -> Unit {
  self.frame.set(0)
  self.opacity.set(self.frames[0].start_opacity().to_double())
  self.xyscale.set(self.frames[0].start_scale().to_double())
  self.delay = self.frames[0].get_delay()
  self.frame_step = 1
}

fn get_frame(self : Animation) -> Frame {
  self.frames[self.frame.now]
}

fn get_delay(self : Animation, frame_id : Int) -> Int {
  if frame_id < self.frames.length() {
    self.frames[frame_id].get_delay()
  } else {
    0
  }
}

pub fn get_delay_until(self : Animation, frame_id : Int) -> Int {
  let mut total : Int = 0
  let mut i = 0
  while i < frame_id {
    if i >= self.frames.length() {
      break
    }
    total += self.frames[i].get_delay()
    i += 1
  }
  total
}

pub fn get_origin(self : Animation) -> Point[Int] {
  self.get_frame().get_origin()
}

pub fn get_dimensions(self : Animation) -> Point[Int] {
  self.get_frame().get_dimensions()
}

pub fn get_head(self : Animation) -> Point[Int] {
  self.get_frame().get_head()
}

pub fn get_bounds(self : Animation) -> Rectangle[Int] {
  self.get_frame().get_bounds()
}
