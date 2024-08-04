// app/src/main/cpp/src/Graphics/Texture.h

struct Texture {
  bitmap : Bitmap?
  mut origin : Point[Int]
  dimensions : Point[Int]
} derive(Default)

pub fn to_string(self : Texture) -> String {
  let bid = self.bitmap.map_or(-1, fn(bitmap) { bitmap.id() })
  let origin = self.origin
  let dimensions = self.dimensions
  "Texture{bid=\(bid), origin=\(origin), dimensions=\(dimensions)}"
}

pub fn debug_write(self : Texture, buffer : Buffer) -> Unit {
  buffer.write_string(self.to_string())
}

fn Texture::from_resource(src : NxNode) -> Texture {
  let loader_name = src.loader.name()
  let src_path = src.path
  // println("loading texture from resource \(loader_name) \(src_path)")
  // TODO: source,_outlink,_inlink
  match src["__b"].desc.as_number() {
    Some(bid) =>
      {
        bitmap: Some(src.loader.load_bitmap(bid.to_int())),
        origin: (src["origin"] |> Point::from_resource).unwrap(),
        dimensions: {
          x: src["__w"].get_int().unwrap(),
          y: src["__h"].get_int().unwrap(),
        },
      }
    None => { bitmap: None, origin: { x: 0, y: 0 }, dimensions: { x: 0, y: 0 } }
  }
}

fn draw(self : Texture, args : DrawArgument) -> Unit {
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

pub fn shift(self : Texture, amount : Point[Int]) -> Unit {
  self.origin -= amount
}

pub fn is_valid(self : Texture) -> Bool {
  self.bitmap.is_empty().not()
}

pub fn width(self : Texture) -> Int {
  self.dimensions.x
}

pub fn height(self : Texture) -> Int {
  self.dimensions.y
}
