///|
pub(all) struct Body {
  stances : Map[
    @types.StanceId,
    Map[@types.BodyLayer, Map[Int, @graphics.Texture]],
  ]
  name : String
}

///| For testing
pub fn Body::default() -> Body {
  { stances: Map::new(), name: "" }
}

///|
fn get_body_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("body")
}

///|
fn Body::load(
  skin : Int,
  drawinfo : @types.BodyDrawInfo
) -> @utils.Future[Body] {
  let strid : String = @string_format.extend_id(skin, 2)
  let loader = get_body_loader()
  let bodynode = loader.load_res(["000020" + strid + ".img"])
  let headnode = loader.load_res(["000120" + strid + ".img"])
  bodynode
  .combine(headnode)
  .map(fn(it) { Body::new(skin, drawinfo, it.0, it.1) })
}

///|
fn Body::new(
  skin : Int,
  drawinfo : @types.BodyDrawInfo,
  bodys : @resource.NxNode,
  heads : @resource.NxNode
) -> Body {
  let stances = @types.stance_name_id_map
    .iter()
    .map(fn(it) {
      let (stance_name, stance) = it
      let stance_body = bodys[stance_name]
      let stance_head = heads[stance_name]
      (stance, new_body_stance(stance, stance_body, stance_head, drawinfo))
    })
    |> Map::from_iter
  let index = skin
  let name = if index < skintypes.length() { skintypes[index] } else { "" }
  { stances, name }
}

///|
fn new_body_stance(
  stance : @types.StanceId,
  stancenode : @resource.NxNode,
  headnode : @resource.NxNode,
  drawinfo : @types.BodyDrawInfo
) -> Map[@types.BodyLayer, Map[Int, @graphics.Texture]] {
  guard stancenode.is_null().not() else { return {} }
  let body_texture_map = Map::new()
  for
    it in @utils.ints().map_while(fn(frame) {
      let framenode = stancenode[frame.to_string()]
      if framenode.is_null() {
        None
      } else {
        Some((frame, framenode))
      }
    }) {
    let (frame, framenode) = it
    for part, partnode in framenode {
      if part != "delay" && part != "face" {
        let z : String = partnode["z"].get_string()
        let layer : @types.BodyLayer = @types.BodyLayer::layer_by_name(z)
        if layer != @types.BodyLayer::BODY_NONE {
          let shift = match layer {
            @types.BodyLayer::HAND_BELOW_WEAPON =>
              drawinfo.get_hand_position(stance, frame) -
              partnode["map"]["handMove"].as_point?().unwrap()
            _ => {
              let mut shift = drawinfo.get_body_position(stance, frame)
              if stance == @types.StanceId::DEAD {
                shift -= @struct.Point::new(5, 4)
              }
              shift -= partnode["map"]["navel"].as_point?().unwrap()
              shift
            }
          }
          let texture = @graphics.Texture::from_resource(partnode)
          texture.shift(shift)
          body_texture_map
          .get_or_init(layer, fn() { Map::new() })
          .set(frame, texture)
        }
      }
    }
    let headsfnode = headnode[frame.to_string()]["head"]
    if headsfnode.is_null().not() {
      let shift = drawinfo.get_head_position(stance, frame)
      let texture = @graphics.Texture::from_resource(headsfnode)
      texture.shift(shift)
      body_texture_map
      .get_or_init(@types.BodyLayer::HEAD, fn() { Map::new() })
      .set(frame, texture)
    }
  }
  body_texture_map
}

///|
let skintypes = [
  "Light", "Tan", "Dark", "Pale", "Blue", "Green", "", "", "", "Grey", "Pink", "Red",
]

///|
pub fn Body::draw(
  self : Body,
  stance : @types.StanceId,
  layer : @types.BodyLayer,
  frame : Int,
  args : @graphics.DrawArgument
) -> Unit {
  let frameit = self.stances[stance]
    .bind(fn(it) { it[layer] })
    .bind(fn(it) { it[frame] })
  match frameit {
    Some(v) => v.draw(args)
    None => ()
  }
}

///|
pub fn Body::get_name(self : Body) -> String {
  self.name
}

///|
pub impl ToJson for Body with to_json(self) -> Json {
  { "name": self.name.to_json() }
}
