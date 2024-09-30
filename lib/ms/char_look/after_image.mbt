struct Afterimage {
  animation : @graphics.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  displayed : Bool
}

pub fn Afterimage::new(
  skill_id : Int,
  name : String,
  stance_name : String,
  level : Int
) -> Afterimage {
  let src_opt = if skill_id > 0 {
    let strid = @string_format.extend_id(skill_id, 7)
    let src = skill_loader().load_res(
      [
        strid.substring(end=3) + ".img",
        "skill",
        strid,
        "afterimage",
        name,
        stance_name,
      ],
    )
    if src.is_null() {
      None
    } else {
      Some(src)
    }
  } else {
    None
  }
  let src = match src_opt {
    Some(src) => src
    None =>
      @resource.character_loader().load_res(
        ["Afterimage", name + ".img", (level / 10).to_string(), stance_name],
      )
  }
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

pub fn Afterimage::default() -> Afterimage {
  {
    animation: @graphics.Animation::default(),
    range: @struct.Rectangle::default(),
    first_frame: 0,
    displayed: true,
  }
}

pub fn skill_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("skill")
}

pub fn get_first_frame(self : Afterimage) -> Int {
  self.first_frame
}

pub fn get_range(self : Afterimage) -> @struct.Rectangle[Int] {
  self.range
}
