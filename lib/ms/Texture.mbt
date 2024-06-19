// app/src/main/cpp/src/Graphics/Texture.h

struct Texture {
  bitmap : Bitmap?
  mut origin : Point[Int]
  dimensions : Point[Int]
} derive(Default)

fn Texture::from_resource(src : NxNode) -> Texture {
  println("loading texture from resource " + src.loader.name() + " " + src.path)
  // TODO: source,_outlink,_inlink
  match src["__b"].desc.as_number() {
    Some(bid) =>
      {
        bitmap: Some(src.loader.load_bitmap(bid.to_int())),
        origin: src["origin"] |> Point::from_resource,
        dimensions: { x: src["__w"].get_int(), y: src["__h"].get_int() },
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
