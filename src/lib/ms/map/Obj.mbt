///| Represents an obj (map decoration) on a map.
struct Obj {
  animation : @graphics.Animation
  pos : Point[Int]
  z : Int
  flip : Bool
}

///|
fn get_object_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("obj")
}

///|
pub fn Obj::load(src : NxNode) -> @utils.Future[Result[Obj, Error]] {
  match src.value() {
    {
      "oS": String(src_oS),
      "l0": String(src_l0),
      "l1": String(src_l1),
      "l2": String(src_l2),
      ..
    } =>
      get_object_loader()
      .load_res(["\{src_oS}.img", src_l0, src_l1, src_l2])
      .map(fn(res) { Obj::from_resource?(src, res) })
    _ => panic()
  }
}

///|
fn Obj::from_resource(src : NxNode, obj_src : NxNode) -> Obj! {
  {
    animation: @graphics.Animation::from_resource_ex!(obj_src),
    pos: @struct.Point::new(src["x"].get_int!(), src["y"].get_int!()),
    flip: src["f"].get_bool!(),
    z: src["z"].get_int!(),
  }
}

///|
pub fn update(self : Obj) -> Unit {
  self.animation.update() |> ignore
}

///|
pub fn draw(self : Obj, viewpos : Point[Int], inter : Double) -> Unit {
  self.animation.draw(
    @graphics.DrawArgument::new(pos=self.pos + viewpos, flip=self.flip),
    inter,
  )
}

///|
pub fn get_z(self : Obj) -> Int {
  self.z
}
