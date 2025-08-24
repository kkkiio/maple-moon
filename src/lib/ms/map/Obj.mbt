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
pub async fn Obj::load(obj : ObjResource) -> Obj raise {
  let oS = obj.oS
  let l0 = obj.l0
  let l1 = obj.l1
  let l2 = obj.l2
  let res = get_object_loader().load_res_async(["\{oS}.img", l0, l1, l2])
  Obj::from_resource(obj, res)
}

///|
fn Obj::from_resource(obj : ObjResource, obj_src : NxNode) -> Obj raise {
  {
    animation: @graphics.Animation::from_resource_ex(obj_src),
    pos: @struct.Point::new(obj.x, obj.y),
    flip: obj.f,
    z: obj.z,
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
