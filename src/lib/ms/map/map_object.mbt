///|
/// Represents an obj (map decoration) on a map.
struct Obj {
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
      // "https://maple-res.kkkiiox.work/Map/Obj",
      "/assets/map/obj",
    ),
    base_url="/assets",
  )
}

///|
struct ObjectAnimationPath {
  l0 : String
  l1 : String
  l2 : String
} derive(Show, Eq, Hash)

///|
pub fn ObjectAnimationPath::from_obj(obj : NxObj) -> ObjectAnimationPath {
  { l0: obj.l0, l1: obj.l1, l2: obj.l2 }
}

///|
pub async fn load_obj_animation(
  object_set_name : String,
  key : ObjectAnimationPath,
) -> @resource.NxAnimation {
  let { l0, l1, l2 } = key
  let res = get_object_loader().load_res_async([
    "\{object_set_name}.img",
    l0,
    l1,
    l2,
  ])
  let animation = @json.from_json(res.value())
  animation
}

///|
pub fn Obj::new(obj : NxObj, animation : @resource.NxAnimation) -> Obj {
  { animation, pos: @struct.Point::new(obj.x, obj.y), flip: obj.f, z: obj.z }
}

///|
/// 将 Obj 动画设置到指定实体上，隐藏时会移除对应 sprite。
/// - `entity`: 需要渲染该 Obj 的实体。
pub fn Obj::attach_entity(self : Obj, entity : @entity.Entity) -> Unit {
  let animation = @graphics.nx_animation_to_selene_animation(
    self.animation,
    flip_x=self.flip,
    loop_=true,
  )
  let sprite = @sprite.Sprite::from_animation(
    animation,
    self.z + @graphics.SCENE_ZINDEX,
  )
  @sprite.sprites.set(entity, sprite)
  @position.positions.set(
    entity,
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
pub fn Obj::get_z(self : Obj) -> Int {
  self.z
}
