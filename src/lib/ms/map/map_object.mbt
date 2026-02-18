///|
using @resource {
  nx_animation_to_selene_animation,
  get_object_loader,
  type NxAnimation,
}

///|
/// Represents an obj (map decoration) on a map.
struct Obj {
  animation : NxAnimation
  pos : Point[Int]
  z : Int
  flip : Bool
  layer : Int
  resource_index : Int
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
) -> NxAnimation {
  let { l0, l1, l2 } = key
  let res = get_object_loader().load_res_async([
    "\{object_set_name}.img",
    l0,
    l1,
    l2,
  ])
  @json.from_json(res.value())
}

///|
pub fn Obj::new(
  obj : NxObj,
  animation : NxAnimation,
  layer : Int,
  resource_index : Int,
) -> Obj {
  {
    animation,
    pos: Point::new(obj.x, obj.y),
    flip: obj.f,
    z: obj.z,
    layer,
    resource_index,
  }
}

///|
/// 将 Obj 动画设置到指定实体上，隐藏时会移除对应 sprite。
/// - `entity`: 需要渲染该 Obj 的实体。
/// - `z_offset`: z 值偏移量，用于计算最终的 z 值。
pub fn Obj::attach_entity(
  self : Obj,
  entity : @entity.Entity,
  z_offset : Int,
) -> Unit {
  let animation = nx_animation_to_selene_animation(
    self.animation,
    loop_=true,
  )
  let transform = if self.flip {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform::new()
  }
  let sprite = @sprite.Sprite::from_animation(
    animation,
    self.z + z_offset,
    transform~,
  )
  @sprite.sprites.set(entity, sprite)
  @position.positions.set(
    entity,
    @position.Position(
      @selene_math.Vec2D(self.pos.x.to_double(), self.pos.y.to_double()),
    ),
  )
}

///|
pub fn Obj::get_z(self : Obj) -> Int {
  self.z
}
