///|
pub(all) struct Texture {
  bitmap : @resource.Bitmap?
  mut origin : @struct.Point[Int]
  dimensions : @struct.Point[Int]
} derive(Default)

///|
pub fn to_string(self : Texture) -> String {
  let bid = self.bitmap.map_or("", fn(bitmap) { bitmap.id })
  let origin = self.origin
  let dimensions = self.dimensions
  "Texture{bid=\{bid}, origin=\{origin}, dimensions=\{dimensions}}"
}

///|
pub impl ToJson for Texture with to_json(self) -> Json {
  {
    "bitmap": self.bitmap.to_json(),
    "origin": self.origin.to_json(),
    "dimensions": self.dimensions.to_json(),
  }
}

///|
pub fn Texture::from_resource(src : @resource.NxNode) -> Texture {
  // TODO: source,_outlink,_inlink
  match src.get_bitmap() {
    Some(bmp) =>
      {
        bitmap: Some(bmp),
        origin: src["origin"].as_point?().unwrap(),
        dimensions: { x: bmp.width, y: bmp.height },
      }
    None => { bitmap: None, origin: { x: 0, y: 0 }, dimensions: { x: 0, y: 0 } }
  }
}

///|
pub fn shift(self : Texture, amount : @struct.Point[Int]) -> Unit {
  self.origin -= amount
}

///|
pub fn width(self : Texture) -> Int {
  self.dimensions.x
}

///|
pub fn height(self : Texture) -> Int {
  self.dimensions.y
}

///|
pub fn get_origin(self : Texture) -> @struct.Point[Int] {
  self.origin
}

///|
pub fn get_dimensions(self : Texture) -> @struct.Point[Int] {
  self.dimensions
}

///|
pub impl Drawable for Texture with draw(self : Texture, args : DrawArgument) -> Unit {
  match self.bitmap {
    None => ()
    Some(bitmap) =>
      GraphicsGL::get().draw_bitmap(
        bitmap,
        args.get_rectangle(self.origin, self.dimensions),
        args.color,
        args.angle,
      )
  }
}
