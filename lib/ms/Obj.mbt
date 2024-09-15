// Represents an obj (map decoration) on a map.
struct Obj {
  animation : Animation
  pos : Point[Int]
  z : Int
  flip : Bool
}

pub fn Obj::from_resource(src : NxNode) -> Obj {
  let map_loader = map_loader()
  let src_oS = src["oS"].as_string().unwrap()
  let src_l0 = src["l0"].as_string().unwrap()
  let src_l1 = src["l1"].as_string().unwrap()
  let src_l2 = src["l2"].as_string().unwrap()
  {
    animation: Animation::from_resource(
      map_loader.load_res(["Obj", "\{src_oS}.img", src_l0, src_l1, src_l2]),
    ),
    pos: Point::new(src["x"].get_int?().unwrap(), src["y"].get_int?().unwrap()),
    flip: src["f"].get_bool?().unwrap(),
    z: src["z"].get_int?().unwrap(),
  }
}

pub fn update(self : Obj) -> Unit {
  self.animation.update() |> ignore
}

pub fn draw(self : Obj, viewpos : Point[Int], inter : Double) -> Unit {
  self.animation.draw(DrawArgument::new14(self.pos + viewpos, self.flip), inter)
}

pub fn get_z(self : Obj) -> Int {
  self.z
}
