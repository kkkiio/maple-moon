/// 物理引擎的核心驱动在 Physics::move_object 函数中，每一帧（tick）都会执行一次，流程如下：
/// 
/// 环境感知 (update_fh):
/// 首先判断物体脚下是否有“立足点”（Foothold）。
/// 更新 PhysicsObject 的 onground 状态、fhslope（坡度）等。
/// 
/// 应用力学公式 (根据类型):
/// 不同类型的物体（普通行走、飞行、游泳）有不同的物理定律。以 move_normal（普通行走）为例：
/// 重力: 如果不在地面且没开启 NO_GRAVITY，vacc (垂直加速度) 增加 gravforce (0.14)。
/// 
/// 摩擦力与坡度:
/// 如果在地面，根据速度计算惯性 inertia。
/// 结合 friction (摩擦系数 0.3) 和 slopefactor (坡度系数 0.1) 计算水平阻力。
/// 这模拟了在斜坡上滑行或平地上减速的效果。
/// 
/// 速度积分: 速度 += 加速度 (hspeed += hacc)。
/// 
/// 碰撞限制 (limit_movement):
/// 在真正移动前，检查预测的路径是否会穿墙或超出地图边界，修正速度或位置。
/// 
/// 执行位移 (do_move):
/// 最终调用 MovingObject.do_move()，执行 位置 += 速度。
/// 
/// 力的累积与清空:
/// 代码中 hforce 和 vforce 代表瞬时力。在 move_normal 中，这些力被加到加速度上后，立即被重置为 0 (phobj.hforce = 0.0)。这意味着除非持续施力（如按住移动键），否则物体会因摩擦力而停止。
/// 
/// 地面吸附与坡度处理:
/// 通过 fhslope 变量，引擎不仅知道是否有地面，还知道地面的倾斜程度。
/// 代码：friction + slopefactor * (1.0 + slopef * -inertia)
/// 这个公式很精妙地处理了上下坡的物理感：上坡时阻力大（减速快），下坡时阻力小甚至会有加速感。
/// 
/// 状态机控制:
/// 通过 PhysicsObjectType (如 FLYING, SWIMMING) 动态切换物理参数。
/// 例如 SWIMMING 状态下有更低的重力 (swimgravforce) 和更高的流体阻力 (swimfriction)。
/// 
/// 总结
/// 这是一个经典的 Euler Integration（欧拉积分） 物理引擎实现：
/// 
/// Force (力) -> Acceleration (加速度)
/// Acceleration (加速度) -> Velocity (速度)
/// Velocity (速度) -> Position (位置)
/// 它的特点是不仅计算碰撞，还模拟了手感（通过复杂的摩擦力和坡度公式），这是 MapleStory 类游戏操作感的关键来源。

///|
/// Physics world wrapper containing foothold collision data.
pub struct Physics {
  fh_tree : FootholdTree
}

///|
/// Gravity acceleration applied to normal objects each tick.
pub let gravforce : Double = 0.14

///|
/// Gravity acceleration applied to swimming objects each tick.
pub let swimgravforce : Double = 0.03

///|
/// Ground friction coefficient for normal movement.
pub let friction : Double = 0.3

///|
/// Extra slope factor used to model uphill/downhill resistance.
pub let slopefactor : Double = 0.1

///|
/// Inertia divisor used when converting speed to ground slip.
pub let groundslip : Double = 3.0

///|
/// Air friction coefficient for flying objects.
pub let flyfriction : Double = 0.05

///|
/// Fluid friction coefficient for swimming objects.
pub let swimfriction : Double = 0.08

///|
/// Build physics world from foothold resource.
pub fn Physics::from_resource(src : NxFootholdTree) -> Physics raise {
  let fh_tree = FootholdTree::from_resource(src)
  { fh_tree, }
}

///|
/// Build an empty physics world for tests or bootstrap.
pub fn empty_physics() -> Physics {
  {
    fh_tree: {
      footholds: Map([]),
      seg_tree: { xs: [], nodes: [], root: -1 },
      null_fh: Foothold::default(),
      walls: @struct.Range::new(-100000, 100000),
      borders: @struct.Range::new(-100000, 100000),
    },
  }
}

///|
/// Advance one physics tick for a single object.
pub fn Physics::move_object(self : Physics, tomove : PhysicsObject) -> Unit {
  // Determine which platform the object is currently on
  self.fh_tree.update_fh(tomove)

  // Use the appropriate physics for the terrain the object is on
  match tomove.t {
    PhysicsObjectType::NORMAL => {
      move_normal(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    PhysicsObjectType::FLYING => {
      move_flying(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    PhysicsObjectType::SWIMMING => {
      move_swimming(tomove)
      self.fh_tree.limit_movement(tomove)
    }
    _ => ()
  }

  // Move the object forward
  tomove.moving_object.do_move()
}

///|
fn move_normal(phobj : PhysicsObject) -> Unit {
  phobj.vacc = 0.0
  phobj.hacc = 0.0
  if phobj.on_ground {
    phobj.vacc += phobj.vforce
    phobj.hacc += phobj.hforce
    if phobj.hacc == 0.0 &&
      phobj.moving_object.hspeed < 0.1 &&
      phobj.moving_object.hspeed > -0.1 {
      phobj.moving_object.hspeed = 0.0
    } else {
      let inertia = phobj.moving_object.hspeed / groundslip
      let mut slopef = phobj.fh_slope
      if slopef > 0.5 {
        slopef = 0.5
      } else if slopef < -0.5 {
        slopef = -0.5
      }
      phobj.hacc -= (friction + slopefactor * (1.0 + slopef * -inertia)) *
        inertia
    }
  } else if phobj.is_flag_not_set(PhysicsObjectFlag::NO_GRAVITY) {
    phobj.vacc += gravforce
  }
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
}

///|
fn move_flying(phobj : PhysicsObject) -> Unit {
  phobj.hacc = phobj.hforce
  phobj.vacc = phobj.vforce
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.hacc -= flyfriction * phobj.moving_object.hspeed
  phobj.vacc -= flyfriction * phobj.moving_object.vspeed
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
  if phobj.hacc == 0.0 &&
    phobj.moving_object.hspeed < 0.1 &&
    phobj.moving_object.hspeed > -0.1 {
    phobj.moving_object.hspeed = 0.0
  }
  if phobj.vacc == 0.0 &&
    phobj.moving_object.vspeed < 0.1 &&
    phobj.moving_object.vspeed > -0.1 {
    phobj.moving_object.vspeed = 0.0
  }
}

///|
fn move_swimming(phobj : PhysicsObject) -> Unit {
  phobj.hacc = phobj.hforce
  phobj.vacc = phobj.vforce
  phobj.hforce = 0.0
  phobj.vforce = 0.0
  phobj.hacc -= swimfriction * phobj.moving_object.hspeed
  phobj.vacc -= swimfriction * phobj.moving_object.vspeed
  if phobj.is_flag_not_set(PhysicsObjectFlag::NO_GRAVITY) {
    phobj.vacc += swimgravforce
  }
  phobj.moving_object.hspeed += phobj.hacc
  phobj.moving_object.vspeed += phobj.vacc
  if phobj.hacc == 0.0 &&
    phobj.moving_object.hspeed < 0.1 &&
    phobj.moving_object.hspeed > -0.1 {
    phobj.moving_object.hspeed = 0.0
  }
  if phobj.vacc == 0.0 &&
    phobj.moving_object.vspeed < 0.1 &&
    phobj.moving_object.vspeed > -0.1 {
    phobj.moving_object.vspeed = 0.0
  }
}

///|
/// Return a snapped integer point right above ground below `position`.
///
/// Warning: this is a discrete placement helper for spawn/NPC placement.
/// It relies on `FootholdTree::get_y_below` (integer y), so do not use it for
/// continuous movement/teleport landing on slopes.
pub fn Physics::get_y_below(
  self : Physics,
  position : Point[Int],
) -> Point[Int] {
  let ground = self.fh_tree.get_y_below(position)
  { x: position.x, y: ground - 1 }
}

///|
/// Access underlying foothold tree.
pub fn Physics::get_fht(self : Physics) -> FootholdTree {
  self.fh_tree
}
