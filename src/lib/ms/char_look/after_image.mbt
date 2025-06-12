///|
struct AfterImage {
  animation : @graphics.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  mut displayed : Bool
}

///|
pub async fn AfterImage::load(
  skill_id : Int,
  name : String,
  stance_name : String,
  level : Int
) -> AfterImage! {
  let src = if skill_id > 0 {
    let strid = @string_format.extend_id(skill_id, 7)
    let skill_src = @skill.skill_loader().load_res_async([
      strid.substring(end=3) + ".img",
      "skill",
      strid,
      "afterimage",
      name,
      stance_name,
    ])
    if skill_src.is_null() {
      let path = [name + ".img", (level / 10).to_string(), stance_name]
      get_afterimage_loader().load_res_async(path)
    } else {
      skill_src
    }
  } else {
    let path = [name + ".img", (level / 10).to_string(), stance_name]
    get_afterimage_loader().load_res_async(path)
  }
  AfterImage::new(src)
}

///|
pub fn AfterImage::new(src : @resource.NxNode) -> AfterImage {
  let range = src.as_rectangle?().unwrap()
  let mut animation = @graphics.Animation::default()
  let mut first_frame = 0
  let displayed = false
  for sub in src {
    let frame = @strconv.parse_int?(sub.name()).or(255)
    if frame < 255 {
      animation = sub |> @graphics.Animation::from_resource
      first_frame = frame
    }
  }
  { animation, range, first_frame, displayed }
}

///|
fn get_afterimage_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("afterimage")
}

///| @alert deprecated "explicitly handle loading"
pub impl Default for AfterImage with default() -> AfterImage {
  {
    animation: @graphics.Animation::default(),
    range: @struct.Rectangle::default(),
    first_frame: 0,
    displayed: true,
  }
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
