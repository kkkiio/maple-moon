///|
pub(all) enum ExpressionId {
  DEFAULT
  BLINK
  HIT
  SMILE
  TROUBLED
  CRY
  ANGRY
  BEWILDERED
  STUNNED
  BLAZE
  BOWING
  CHEERS
  CHU
  DAM
  DESPAIR
  GLITTER
  HOT
  HUM
  LOVE
  OOPS
  PAIN
  SHINE
  VOMIT
  WINK
} derive(Eq, Compare, Hash)

///|
pub impl Default for ExpressionId with default() -> ExpressionId {
  ExpressionId::DEFAULT
}

///|
pub let expression_names : @immut/sorted_map.SortedMap[ExpressionId, String] = @immut/sorted_map.from_array([
    (ExpressionId::DEFAULT, "default"),
    (ExpressionId::BLINK, "blink"),
    (ExpressionId::HIT, "hit"),
    (ExpressionId::SMILE, "smile"),
    (ExpressionId::TROUBLED, "troubled"),
    (ExpressionId::CRY, "cry"),
    (ExpressionId::ANGRY, "angry"),
    (ExpressionId::BEWILDERED, "bewildered"),
    (ExpressionId::STUNNED, "stunned"),
    (ExpressionId::BLAZE, "blaze"),
    (ExpressionId::BOWING, "bowing"),
    (ExpressionId::CHEERS, "cheers"),
    (ExpressionId::CHU, "chu"),
    (ExpressionId::DAM, "dam"),
    (ExpressionId::DESPAIR, "despair"),
    (ExpressionId::GLITTER, "glitter"),
    (ExpressionId::HOT, "hot"),
    (ExpressionId::HUM, "hum"),
    (ExpressionId::LOVE, "love"),
    (ExpressionId::OOPS, "oops"),
    (ExpressionId::PAIN, "pain"),
    (ExpressionId::SHINE, "shine"),
    (ExpressionId::VOMIT, "vomit"),
    (ExpressionId::WINK, "wink"),
  ],
)

///|
pub impl ToJson for ExpressionId with to_json(self) {
  expression_names.get(self).unwrap().to_json()
}

///|
let all_expressions : FixedArray[ExpressionId] = expression_names.keys_as_iter()
  |> FixedArray::from_iter()

///|
pub fn byaction(action : Int) -> ExpressionId {
  let adjusted_action = action - 98
  if adjusted_action < all_expressions.length() {
    all_expressions[adjusted_action]
  } else {
    println("Unknown Expression::Id action: [\{action}]")
    ExpressionId::DEFAULT
  }
}

///|
struct Face {
  expressions : Map[ExpressionId, Map[Int, FaceFrame]]
  name : String
} derive(Default)

///|
pub impl ToJson for Face with to_json(self) -> Json {
  { "name": self.name.to_json() }
}

///|
struct FaceFrame {
  texture : @resource.NxTexture
  delay : Int
}

///|
pub fn FaceFrame::from_resource(src : Json) -> FaceFrame raise {
  guard src is { "face": face, .. }
  let texture : @resource.NxTexture = @json.from_json(face)
  // let shift : Point[Int] = face["map"]["brow"].as_point?().unwrap()
  let shift = match face {
    { "map": { "brow": brow, .. }, .. } => @json.from_json(brow)
    _ => @struct.Point::default()
  }
  // texture.shift(-shift)
  let texture = { ..texture, origin: texture.origin + shift }
  let delay : Int = match src {
    { "delay": Number(delay, ..), .. } => delay.to_int()
    _ => 2500
  }
  { texture, delay }
}

///|
fn get_face_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "face",
    loader=@resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Character/Face",
    ),
  )
}

///|
pub async fn Face::load(faceid : Int) -> Face {
  let strid = "000" + faceid.to_string()
  let facenode = get_face_loader().load_res_async(["\{strid}.img"])
  Face::new(faceid, facenode.value())
}

///|
pub fn Face::new(faceid : Int, facenode : Json) -> Face raise {
  guard facenode is Json::Object(facenode)
  let expressions = Map::new()
  for exp, _ in expression_names {
    let frames = Map::new()
    if exp == ExpressionId::DEFAULT {
      frames.set(0, FaceFrame::from_resource(facenode["default"]))
    } else {
      let expname = expression_names[exp]
      let expnode = facenode[expname]
      guard expnode is Json::Object(expnode)
      let mut frame = 0
      while true {
        if expnode.get(frame.to_string()) is Some(framenode) {
          frames.set(frame, FaceFrame::from_resource(framenode))
          frame += 1
        } else {
          break
        }
      }
    }
    expressions.set(exp, frames)
  }
  let name = face_names.get(faceid.to_string()).unwrap_or("")
  { expressions, name }
}

///|
pub fn Face::draw(
  self : Face,
  expression : ExpressionId,
  frame : Int,
  args : @graphics.DrawArgument,
) -> Unit {
  // match self.expressions[expression].get(frame) {
  //   Some(frameit) => frameit.texture.draw(args)
  //   None => ()
  // }
}

///|
pub fn Face::nextframe(
  self : Face,
  expression : ExpressionId,
  frame : Int,
) -> Int {
  if self.expressions[expression].contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

///|
pub fn Face::get_delay(
  self : Face,
  expression : ExpressionId,
  frame : Int,
) -> Int {
  match self.expressions[expression].get(frame) {
    Some(delayit) => delayit.delay
    None => 100
  }
}

///|
pub fn Face::get_name(self : Face) -> String {
  self.name
}
