pub enum ExpressionId {
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
} derive(Eq, Compare)

pub fn ExpressionId::default() -> ExpressionId {
  ExpressionId::DEFAULT
}

pub let expression_names : @immut/sorted_map.T[ExpressionId, String] = @immut/sorted_map.from_array(
  [
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

let all_expressions : FixedArray[ExpressionId] = expression_names.keys()
  |> FixedArray::from_array

pub fn byaction(action : Int) -> ExpressionId {
  let adjusted_action = action - 98
  if adjusted_action < all_expressions.length() {
    all_expressions[adjusted_action]
  } else {
    println("Unknown Expression::Id action: [\{action}]")
    ExpressionId::DEFAULT
  }
}

struct Face {
  expressions : @immut/sorted_map.T[ExpressionId, Map[Int, FaceFrame]]
  name : String
}

struct FaceFrame {
  texture : Texture
  delay : Int
}

pub fn FaceFrame::from_resource(src : NxNode) -> FaceFrame {
  let texture = Texture::from_resource(src["face"])
  let shift : Point[Int] = Point::from_resource(src["face"]["map"]["brow"]).unwrap()
  texture.shift(-shift)
  let mut delay : Int = src["delay"].get_int().unwrap()
  if delay == 0 {
    delay = 2500
  }
  { texture, delay }
}

let string_loader = @resource.string_loader

pub fn Face::new(faceid : Int) -> Face {
  let strid = "000" + faceid.to_string()
  let loader = character_loader()
  let facenode = loader.load_res(["Face", "\{strid}.img"])
  let expressions = expression_names.map_with_key(
    fn(exp, _v) {
      let frames = Map::new()
      if exp == ExpressionId::DEFAULT {
        frames.set(0, FaceFrame::from_resource(facenode["default"]))
      } else {
        let expname = expression_names[exp].unwrap()
        let expnode = facenode[expname]
        let mut frame = 0
        while true {
          let framenode = expnode[frame.to_string()]
          if framenode.is_null() {
            break
          } else {
            frames.set(frame, FaceFrame::from_resource(framenode))
            frame += 1
          }
        }
      }
      frames
    },
  )
  let string_loader = string_loader()
  let name = string_loader.load_res(
    ["Eqp.img", "Eqp", "Face", "\{faceid}", "name"],
  ).get_string()
  { expressions, name }
}

pub fn draw(
  self : Face,
  expression : ExpressionId,
  frame : Int,
  args : DrawArgument
) -> Unit {
  match self.expressions[expression].unwrap().get(frame) {
    Some(frameit) => frameit.texture.draw(args)
    None => ()
  }
}

pub fn nextframe(self : Face, expression : ExpressionId, frame : Int) -> Int {
  if self.expressions[expression].unwrap().contains(frame + 1) {
    frame + 1
  } else {
    0
  }
}

pub fn get_delay(self : Face, expression : ExpressionId, frame : Int) -> Int {
  match self.expressions[expression].unwrap().get(frame) {
    Some(delayit) => delayit.delay
    None => 100
  }
}

pub fn get_name(self : Face) -> String {
  self.name
}
