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
      obj.get("lt").or(Json::null()),
      path=path.add_key("lt"),
    )
    let right_bottom = @json.from_json(
      obj.get("rb").or(Json::null()),
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
  self : AfterNxImageResource
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
} derive(ToJson)

///|
pub fn AfterImage::new(
  resource : AfterImageResource,
  image_loader : @resource.ImageLoader
) -> AfterImage {
  let range = resource.range
  if range.is_empty() {
    @log.error({}, "afterimage range is empty")
    panic()
  }
  let animation = @graphics.Animation::new(
    resource.animation,
    "afterimage",
    image_loader,
  )
  let first_frame = resource.first_frame
  let displayed = false
  { animation, range, first_frame, displayed }
}

///|
test "parse afterimage" {
  let stab_t1_json : Json = {
    "2": {
      "0": {
        "__h": 45,
        "__w": 72,
        "delay": 30,
        "origin": [97, 41],
        "__i": "/Character/Afterimage/spritesheets/poleArm.img#291283",
      },
      "1": {
        "__h": 45,
        "__w": 72,
        "a1": 0,
        "delay": 200,
        "origin": [135, 41],
        "__i": "/Character/Afterimage/spritesheets/poleArm.img#291284",
      },
    },
    "lt": [-130, -33],
    "rb": [-36, -4],
  }
  let resource : AfterNxImageResource = @json.from_json(stab_t1_json)
  @json.inspect(resource.simplify(), content={
    "animation": {
      "blend": false,
      "frames": [
        {
          "texture": {
            "bitmap": {
              "$tag": "Path",
              "0": "/Character/Afterimage/spritesheets/poleArm.img#291283",
              "1": 72,
              "2": 45,
            },
            "origin": [97, 41],
          },
          "delay": 30,
          "bounds": { "lt": [0, 0], "rb": [0, 0] },
          "head": [0, 0],
          "opacities": [255, 255],
          "scales": [100, 100],
        },
        {
          "texture": {
            "bitmap": {
              "$tag": "Path",
              "0": "/Character/Afterimage/spritesheets/poleArm.img#291284",
              "1": 72,
              "2": 45,
            },
            "origin": [135, 41],
          },
          "delay": 200,
          "bounds": { "lt": [0, 0], "rb": [0, 0] },
          "head": [0, 0],
          "opacities": [255, 0],
          "scales": [100, 100],
        },
      ],
      "zigzag": false,
    },
    "range": { "lt": [-130, -33], "rb": [-36, -4] },
    "first_frame": 2,
  })
}

///|
pub fn get_afterimage_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("afterimage")
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
