///|
pub(all) struct Texture {
  bitmap : @resource.Bitmap?
  mut origin : @struct.Point[Int]
  dimensions : @struct.Point[Int]
} derive(Default)

///|
pub fn Texture::to_string(self : Texture) -> String {
  let bid = self.bitmap.map_or("", fn(bitmap) { bitmap.id })
  let origin = self.origin
  let dimensions = self.dimensions
  "Texture{bid=\{bid}, origin=\{origin}, dimensions=\{dimensions}}"
}

///|
pub impl ToJson for Texture with to_json(self) -> Json {
  match self.bitmap {
    Some(bitmap) =>
      {
        "bitmap": bitmap.to_json(),
        "origin": self.origin.to_json(),
        "dimensions": self.dimensions.to_json(),
      }
    None => {}
  }
}

///|
pub fn Texture::from_resource(src : @resource.NxNode) -> Texture {
  // TODO: source,_outlink,_inlink
  match src.get_bitmap() {
    Some(bmp) =>
      {
        bitmap: Some(bmp),
        origin: (try? src["origin"].as_point()).unwrap(),
        dimensions: { x: bmp.width, y: bmp.height },
      }
    None => { bitmap: None, origin: { x: 0, y: 0 }, dimensions: { x: 0, y: 0 } }
  }
}

///|
pub fn Texture::load(
  resource : TextureResource,
  loader_name : String,
  image_loader : @resource.ImageLoader,
) -> Texture {
  let origin = resource.origin
  match resource.bitmap {
    Bid(bid, w, h) => {
      let bitmap = image_loader.load_image(bid)
      {
        bitmap: Some({
          image: bitmap,
          id: loader_name + "/" + bid.to_string(),
          width: w,
          height: h,
        }),
        origin,
        dimensions: { x: w, y: h },
      }
    }
    Path(path, w, h) => {
      let bitmap = image_loader.load_image_by_path(path)
      {
        bitmap: Some({
          image: bitmap,
          id: loader_name + "/" + path,
          width: w,
          height: h,
        }),
        origin,
        dimensions: { x: w, y: h },
      }
    }
  }
}

///|
struct TextureResource {
  bitmap : @resource.BitmapResource
  origin : @struct.Point[Int]
} derive(ToJson)

///|
pub impl @json.FromJson for TextureResource with from_json(json, path) -> TextureResource raise @json.JsonDecodeError {
  // TODO: source,_outlink,_inlink
  let bitmap : @resource.BitmapResource = @json.from_json(json)
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let origin = @json.from_json(
    obj.get("origin").unwrap_or(Json::null()),
    path=path.add_key("origin"),
  )
  { bitmap, origin }
}

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

///|
pub(all) struct NxFrame(@sprite.AnimationFrame)

///|
pub impl @json.FromJson for NxFrame with from_json(json, path) -> NxFrame raise @json.JsonDecodeError {
  match json {
    {
      "__i": String(sprite_path),
      "__w": Number(w, ..),
      "__h": Number(h, ..),
      ..
    } => {
      let offset = match json {
        { "__off": [Number(offx, ..), Number(offy, ..)], .. } =>
          @selene_math.Vec2D(offx, offy)
        _ => @selene_math.Vec2D(0, 0)
      }
      NxFrame(@sprite.AnimationFrame::{
        sprite_path,
        size: @selene_math.Vec2D(w, h),
        offset,
      })
    }
    _ => raise @json.JsonDecodeError((path, "invalid nx frame"))
  }
}
