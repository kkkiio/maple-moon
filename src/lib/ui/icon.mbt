///|
struct LazyVar[T] {
  mut value : T?
  newf : () -> T
}

///|
pub fn LazyVar::make[T](newf : () -> T) -> LazyVar[T] {
  { value: None, newf }
}

///|
pub fn get[T](self : LazyVar[T]) -> T {
  match self.value {
    Some(v) => v
    None => {
      let v = (self.newf)()
      self.value = Some(v)
      v
    }
  }
}

///|
let countset : LazyVar[@graphics.Charset] = LazyVar::make(fn() {
  let ui_loader = common_ui_loader()
  @graphics.Charset::from_resource(
    ui_loader.load_res(["Basic.img", "ItemNo"]),
    @graphics.CharsetAlignment::LEFT,
  )
})

///|
pub(all) struct IconModel {
  mut count : Int?
  mut dragged : Bool
  mut cursor_offset : @struct.Point[Int]
} derive(ToJson)

///|
pub fn IconModel::new(count : Int?) -> IconModel {
  { count, dragged: false, cursor_offset: @struct.Point::default() }
}

///|
pub fn IconModel::draw(
  self : IconModel,
  position : @struct.Point[Int],
  texture : @graphics.Texture
) -> Unit {
  let opacity = if self.dragged { 0.5 } else { 1.0 }
  texture.draw(@graphics.DrawArgument::new7(position.shift_y(32), opacity))
  match self.count {
    Some(count) =>
      countset
      .get()
      .draw_text(
        count.to_string(),
        @graphics.DrawArgument::new(pos=position + @struct.Point::new(0, 20)),
      )
      |> ignore
    None => ()
  }
}

///|
pub fn IconModel::get_bounds(
  texture : @graphics.Texture
) -> @struct.Rectangle[Int] {
  let lt = @struct.Point::new(0, 32) - texture.origin
  let rb = lt + texture.dimensions
  @struct.Rectangle::new(lt, rb)
}
