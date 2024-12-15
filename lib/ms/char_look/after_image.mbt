struct Afterimage {
  animation : @graphics.Animation
  range : @struct.Rectangle[Int]
  first_frame : Int
  mut displayed : Bool
}

pub fn Afterimage::load(
  skill_id : Int,
  name : String,
  stance_name : String,
  level : Int
) -> @utils.Future[Afterimage] {
  ( if skill_id > 0 {
  let strid = @string_format.extend_id(skill_id, 7)
    @skill.skill_loader().load_res(
      [
        strid.substring(end=3) + ".img",
        "skill",
        strid,
        "afterimage",
        name,
        stance_name,
      ],
    ).map(fn(src) {
      if src.is_null(){
        None
      }else {
        Some(src)
      } })
  }else {
    @utils.Future::from_value(None)
  } ) .bind(
    fn(opt) {
      opt.map_or_else(
        fn() {
          afterimage_loader.load_res(
            [name + ".img", (level / 10).to_string(), stance_name],
          )
        },
        fn(src) { @utils.Future::from_value(src) },
      )
    },
  )
  .map(fn(src) { Afterimage::new(src) })
}

pub fn Afterimage::new(src : @resource.NxNode) -> Afterimage {
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

// @alert deprecated "explicitly handle loading"
pub fn Afterimage::default() -> Afterimage {
  {
    animation: @graphics.Animation::default(),
    range: @struct.Rectangle::default(),
    first_frame: 0,
    displayed: true,
  }
}

pub fn get_first_frame(self : Afterimage) -> Int {
  self.first_frame
}

pub fn get_range(self : Afterimage) -> @struct.Rectangle[Int] {
  self.range
}

pub fn update(self : Afterimage, stframe : Int, timestep : Int) -> Unit {
  if self.displayed.not() && stframe >= self.first_frame {
    self.displayed = self.animation.update(timestep~)
  }
}

let afterimage_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "afterimage",
)
