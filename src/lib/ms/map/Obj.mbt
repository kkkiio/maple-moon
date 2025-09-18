///|
/// Represents an obj (map decoration) on a map.
struct Obj {
  entity : @system.Entity
  animation : @resource.NxAnimation
  pos : Point[Int]
  z : Int
  flip : Bool
}

///|
fn get_object_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "obj",
    loader=@resource.DirResourceLoader::new(
      "https://maple-res.kkkiiox.work/Map/Obj",
    ),
  )
}

///|
pub async fn Obj::load(obj : NxObj) -> Obj raise {
  let oS = obj.oS
  let l0 = obj.l0
  let l1 = obj.l1
  let l2 = obj.l2
  let res = get_object_loader().load_res_async(["\{oS}.img", l0, l1, l2])
  let animation = @json.from_json(res.value())
  Obj::new(obj, animation)
}

///|
fn Obj::new(obj : NxObj, animation : @resource.NxAnimation) -> Obj {
  {
    entity: @system.Entity::new(),
    animation,
    pos: @struct.Point::new(obj.x, obj.y),
    flip: obj.f,
    z: obj.z,
  }
}

///|
pub fn update(self : Obj) -> Unit {
  // self.animation.update() |> ignore
}

///|
pub fn Obj::set_sprites(self : Obj) -> Unit {
  let transform = if self.flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform::new()
  }
  let sprite = @graphics.nx_animation_to_selene_sprite(
    self.animation,
    z=self.z + @graphics.SCENE_ZINDEX,
    transform~,
  )
  @sprite.sprites.set(self.entity, sprite)
  @position.positions.set(
    self.entity,
    @position.Position(
      @selene_math.Vec2D(self.pos.x.to_double(), self.pos.y.to_double()),
    ),
  )
  // self.animation.draw(
  //   @graphics.DrawArgument::new(pos=self.pos + viewpos, flip=self.flip),
  //   inter,
  // )
}

///|
pub fn get_z(self : Obj) -> Int {
  self.z
}
