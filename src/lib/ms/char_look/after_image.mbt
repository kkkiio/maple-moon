///|
struct AfterImage {
  animation : @graphics.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  mut displayed : Bool
}

///|
struct AfterNxImageResource {
  animation : @graphics.AnimationResource
  range : @struct.Rectangle[Int]
  first_frame : Int
}

///|
pub impl @json.FromJson for AfterNxImageResource with from_json(json, path) -> AfterNxImageResource raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }

  // Parse range from "lt" and "rb" fields
  let range = {
    let left_top = @json.from_json(
      obj.get("lt").unwrap_or(Json::null()),
      path=path.add_key("lt"),
    )
    let right_bottom = @json.from_json(
      obj.get("rb").unwrap_or(Json::null()),
      path=path.add_key("rb"),
    )
    @struct.Rectangle::new(left_top, right_bottom)
  }

  // Find the first numeric key and parse animation from it
  let mut first_frame = 0
  let mut animation_json = Json::null()
  for key, value in obj {
    match (try? @strconv.parse_int(key)) {
      Ok(frame_num) => {
        first_frame = frame_num
        animation_json = value
        break
      }
      Err(_) => continue
    }
  }
  if animation_json is Json::Null {
    raise @json.JsonDecodeError((path, "no frame data found"))
  }
  let animation = @json.from_json(
    animation_json,
    path=path.add_key(first_frame.to_string()),
  )
  { animation, range, first_frame }
}

///|
pub fn AfterNxImageResource::simplify(
  self : AfterNxImageResource,
) -> AfterImageResource {
  {
    animation: self.animation,
    range: self.range,
    first_frame: self.first_frame,
  }
}

///|
struct AfterImageResource {
  animation : @graphics.AnimationResource
  range : @struct.Rectangle[Int]
  first_frame : Int
}

///|
pub fn AfterImage::new(resource : AfterImageResource) -> AfterImage {
  let range = resource.range
  if range.is_empty() {
    @log.error({}, "afterimage range is empty")
    panic()
  }
  let animation = @graphics.Animation::new(resource.animation)
  let first_frame = resource.first_frame
  let displayed = false
  { animation, range, first_frame, displayed }
}

///|
pub fn get_afterimage_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "afterimage",
    loader=@resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Character/Afterimage",
    ),
  )
}

///|
pub fn get_first_frame(self : AfterImage) -> Int {
  self.first_frame
}

///|
pub fn get_range(self : AfterImage) -> @struct.Rectangle[Int] {
  self.range
}

///|
pub fn update(self : AfterImage, stframe : Int, timestep : Int) -> Unit {
  if not(self.displayed) && stframe >= self.first_frame {
    self.displayed = self.animation.update(timestep~)
  }
}
