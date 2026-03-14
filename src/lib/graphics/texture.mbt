///|
#deprecated("use @resource.NxTexture instead")
pub(all) struct Texture {
  bitmap : @sprite.AnimationFrame?
  mut origin : @struct.Point[Int]
  dimensions : @struct.Point[Int]
} derive(Default)

///|
pub fn Texture::to_string(self : Texture) -> String {
  let origin = self.origin
  let dimensions = self.dimensions
  "Texture{origin=\{origin}, dimensions=\{dimensions}}"
}

///|
pub impl ToJson for Texture with to_json(self) -> Json {
  match self.bitmap {
    Some(bitmap) =>
      {
        "bitmap": @asset.image_path(bitmap.image).unwrap_or("").to_json(),
        "origin": self.origin.to_json(),
        "dimensions": self.dimensions.to_json(),
      }
    None => {}
  }
}

///|
pub fn Texture::from_resource(src : @resource.NxNode) -> Texture {
  // TODO: source,_outlink,_inlink
  let v = src.value()
  if v is Null {
    return { bitmap: None, origin: { x: 0, y: 0 }, dimensions: { x: 0, y: 0 } }
  }
  let tex : @resource.NxTexture = @json.from_json(v) catch {
    err => {
      @log.error("failed to parse nx texture", data={ "err": err })
      panic()
    }
  }
  {
    bitmap: Some(@sprite.AnimationFrame::{
      image: @asset.load_image(tex.i),
      size: @selene_math.Vec2D(tex.w.to_double(), tex.h.to_double()),
      offset: @selene_math.Vec2D(
        tex.offset.x.to_double(),
        tex.offset.y.to_double(),
      ),
      pivot: @selene_math.Vec2D(
        tex.origin.x.to_double(),
        tex.origin.y.to_double(),
      ),
      duration: 0.0,
    }),
    origin: tex.origin,
    dimensions: { x: tex.w, y: tex.h },
  }
}

///|
pub fn Texture::load(tex : @resource.NxTexture) -> Texture {
  {
    bitmap: Some(@sprite.AnimationFrame::{
      image: @asset.load_image(tex.i),
      size: @selene_math.Vec2D(tex.w.to_double(), tex.h.to_double()),
      offset: @selene_math.Vec2D(
        tex.offset.x.to_double(),
        tex.offset.y.to_double(),
      ),
      pivot: @selene_math.Vec2D(
        tex.origin.x.to_double(),
        tex.origin.y.to_double(),
      ),
      duration: 0.0,
    }),
    origin: tex.origin,
    dimensions: { x: tex.w, y: tex.h },
  }
}

///|

///|
pub fn Texture::shift(self : Texture, amount : @struct.Point[Int]) -> Unit {
  self.origin -= amount
}

///|
pub fn Texture::width(self : Texture) -> Int {
  self.dimensions.x
}

///|
pub fn Texture::height(self : Texture) -> Int {
  self.dimensions.y
}

///|
pub fn Texture::get_origin(self : Texture) -> @struct.Point[Int] {
  self.origin
}

///|
pub fn Texture::get_dimensions(self : Texture) -> @struct.Point[Int] {
  self.dimensions
}
