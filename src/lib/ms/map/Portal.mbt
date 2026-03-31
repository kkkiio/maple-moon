///|
/// 传送门
struct NxPortal {
  /// portal name
  pn : String
  /// target map id. `999999999` 通常表示无目标 (常用于出生点).
  tm : Int
  /// target portal name.
  tn : String
  x : Int
  y : Int
  /// portal type
  pt : PortalType
} derive(Show, @json.FromJson, ToJson)

///|
pub(all) enum PortalType {
  /// Start Point (`sp`)。
  ///
  /// 用作出生/复活落点；通常 `tm = 999999999`，本身不触发传送。
  SPAWN = 0
  /// Portal Invisible (`pi`)。
  ///
  /// 不可见的普通传送门；需要玩家主动进入，资源层面可直接传送。
  INVISIBLE = 1
  /// Portal Visible (`pv`)。
  ///
  /// 常见的可见发光传送门；需要玩家主动进入，资源层面可直接传送。
  REGULAR = 2
  /// Portal Collision (`pc`)。
  ///
  /// 碰撞即触发的传送门；资源语义上属于自动触发 warp。
  COLLISION = 3
  /// Portal Changable (`pg`)。
  ///
  /// 资料页描述为“被其他 portal 指向时，会落到一个 `sp`”，细节仍不明确。
  TYPE4 = 4
  /// Portal Changable Invisible (`pgi`)。
  ///
  /// 与 `TYPE4` 类似，但不可见；细节仍不明确。
  TYPE5 = 5
  /// Town Portal Point (`tp`)。
  ///
  /// 用于 Mystic Door / Town Portal 这类双向门的落点与动画锚点。
  WARP = 6
  /// Portal Script (`ps`)。
  ///
  /// 进入时执行 `script`，自身不直接依赖 `tm/tn` 做普通传送。
  SCRIPTED = 7
  /// Portal Script Invisible (`psi`)。
  ///
  /// 不可见的脚本传送门；进入时执行 `script`。
  SCRIPTED_INVISIBLE = 8
  /// Portal Collision Script (`pcs`)。
  ///
  /// 碰撞即自动执行 `script`。
  SCRIPTED_COLLISION = 9
  /// Portal Hidden (`ph`)。
  ///
  /// 隐藏门；通常平时不明显，靠近/触碰后显示线索或门体。
  HIDDEN = 10
  /// Portal Script Hidden (`psh`)。
  ///
  /// 带隐藏外观的脚本门；进入时执行 `script`，同时保留 hidden 表现。
  SCRIPTED_HIDDEN = 11
  /// Portal Collision Jump (`pcj`)。
  ///
  /// 自动触发的弹跳门，只施加垂直冲量；常见于 jump quest。
  SPRING1 = 12
  /// Portal Collision Custom (`pci`)。
  ///
  /// 自动触发的自定义冲量门，可按资源里的 `horizontalImpact` /
  /// `verticalImpact` 施加 X/Y 方向速度。
  SPRING2 = 13
  /// Portal Collision Changeable? (`pcig`)。
  ///
  /// 资料页标为未知类型；推测与 collision/changeable 相关，但未有可靠结论。
  TYPE14 = 14
} derive(Eq, Compare, Show, ToJson, Hash)

///|
pub fn PortalType::typebyid(id : Int) -> PortalType? {
  let t = match id {
    0 => PortalType::SPAWN
    1 => PortalType::INVISIBLE
    2 => PortalType::REGULAR
    3 => PortalType::COLLISION
    4 => PortalType::TYPE4
    5 => PortalType::TYPE5
    6 => PortalType::WARP
    7 => PortalType::SCRIPTED
    8 => PortalType::SCRIPTED_INVISIBLE
    9 => PortalType::SCRIPTED_COLLISION
    10 => PortalType::HIDDEN
    11 => PortalType::SCRIPTED_HIDDEN
    12 => PortalType::SPRING1
    13 => PortalType::SPRING2
    14 => PortalType::TYPE14
    _ => return None
  }
  Some(t)
}

///|
pub fn PortalType::is_auto_trigger(self : PortalType) -> Bool {
  match self {
    PortalType::COLLISION => true
    _ => false
  }
}

///|
pub fn PortalType::is_manual_trigger(self : PortalType) -> Bool {
  !self.is_auto_trigger()
}

///|
pub impl @json.FromJson for PortalType with from_json(json, path) -> PortalType {
  match json {
    Number(n, ..) =>
      PortalType::typebyid(n.to_int()).unwrap_or_error(
        @json.JsonDecodeError((path, "Unknown portal type \{n}")),
      )
    _ => raise @json.JsonDecodeError((path, "Expected a number"))
  }
}

///|
pub(all) struct PortalWarpInfo {
  map_id : Int
  toname : String
  name : String
  /// whether the target is in the current map
  intra_map : Bool
} derive(Show)

///|
fn PortalWarpInfo::new(
  m : Int,
  i : Bool,
  tn : String,
  n : String,
) -> PortalWarpInfo {
  { map_id: m, toname: tn, name: n, intra_map: i }
}

///|
struct Portal {
  animation : @ms_animation.Animation?
  t : PortalType
  name : String
  position : Point[Int]
  warp_info : PortalWarpInfo
  mut touched : Bool
}

///|
pub fn Portal::new(
  animation : @ms_animation.Animation?,
  t : PortalType,
  name : String,
  intramap : Bool,
  position : Point[Int],
  tomap : Int,
  toname : String,
) -> Portal {
  {
    animation,
    t,
    name,
    position,
    warp_info: PortalWarpInfo::new(tomap, intramap, toname, name),
    touched: false,
  }
}

///|
/// Update the portal's touched state based on the touch position.
pub fn Portal::update_touched(
  self : Portal,
  entity : @entity.Entity,
  touch_pos : Point[Int]?,
) -> Unit {
  self.touched = touch_pos is Some(touch_pos) &&
    self.bounds().contains(touch_pos)
  let visible = self.t != PortalType::HIDDEN || self.touched
  @visibility.visibilities().set(
    entity,
    if visible {
      @visibility.Visibility::Visible
    } else {
      @visibility.Visibility::Hidden
    },
  )
}

///|
pub fn Portal::get_name(self : Portal) -> String {
  self.name
}

///|
pub fn Portal::get_type(self : Portal) -> PortalType {
  self.t
}

///|
pub fn Portal::get_position(self : Portal) -> Point[Int] {
  self.position
}

///|
pub fn Portal::bounds(self : Portal) -> @struct.Rectangle[Int] {
  let lt = self.position + @struct.Point::new(-25, -100)
  let rb = self.position + @struct.Point::new(25, 25)
  @struct.Rectangle::new(lt, rb)
}

///|
pub fn Portal::getwarpinfo(self : Portal) -> PortalWarpInfo {
  self.warp_info
}
