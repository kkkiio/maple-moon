///|
/// One animation metadata node declared in `mx.json.stance_nodes`.
pub struct MxMobAnimNode {
  /// Animation tag in the Mob's tagged spritesheet.
  path_key : String
  /// Total animation duration in milliseconds.
  total_duration_ms : Int
  /// Whether this stance should loop.
  loop_ : Bool
  /// First-frame head offset metadata.
  first_head : @struct.Point[Int]?
  /// First-frame bounds metadata.
  first_bounds : @struct.Rectangle[Int]?
}

///|
/// One effect node bound to attack/skill metadata.
pub struct MxMobEffectNode {
  /// Effect animation tag in the Mob's tagged spritesheet.
  path_key : String
  /// Extra z offset applied on top of effect layer base z.
  z : Int
  /// Whether this effect is area warning.
  is_area_warning : Bool
}

///|
/// Attack info metadata parsed from `mx.json.attack_nodes.*.info`.
pub struct MxMobAttackInfo {
  /// Optional attack range rectangle.
  range : @struct.Rectangle[Int]?
  /// Attack type id.
  type_ : Int
  /// MP consume.
  con_mp : Int
  /// Whether this attack is magic.
  magic : Bool
}

///|
/// One attack metadata node in `mx.json.attack_nodes`.
pub struct MxMobAttackNode {
  /// Attack id.
  id : Int
  /// Attack info metadata.
  info : MxMobAttackInfo
  /// Main animation path key (`attackN`).
  animation_path_key : String
  /// Effect nodes declared under this attack.
  effects : Array[MxMobEffectNode]
}

///|
/// One skill metadata node in `mx.json.skill_nodes`.
pub struct MxMobSkillNode {
  /// Skill id.
  skill_id : Int
  /// Skill action index.
  action : Int
  /// Main animation path key (`skillN`).
  animation_path_key : String
  /// Effect nodes declared under this skill.
  effects : Array[MxMobEffectNode]
}

///|
/// Runtime metadata parsed from `Mob/<id>.img/mx.json`.
pub struct MxMob {
  /// Mob info object.
  info : MobInfo
  /// Stance animation nodes keyed by stance name (`stand/move/fly/jump/hit1/die1`).
  stance_nodes : Map[String, MxMobAnimNode]
  /// Attack nodes keyed by attack id.
  attack_nodes : Map[Int, MxMobAttackNode]
  /// Skill nodes keyed by skill id.
  skill_nodes : Map[Int, MxMobSkillNode]
  /// Tagged Aseprite JSON path relative to this `mx.json`.
  animations_path : String
}

///|
fn parse_point_json(
  json : Json,
  path : @json.JsonPath,
) -> @struct.Point[Int] raise @json.JsonDecodeError {
  match json {
    { "x": Number(x, ..), "y": Number(y, ..), .. } =>
      { x: x.to_int(), y: y.to_int() }
    _ => raise @json.JsonDecodeError((path, "point should be {x,y}"))
  }
}

///|
fn parse_rect_json(
  json : Json,
  path : @json.JsonPath,
) -> @struct.Rectangle[Int] raise @json.JsonDecodeError {
  match json {
    { "lt": lt, "rb": rb, .. } =>
      Rectangle(
        parse_point_json(lt, path.add_key("lt")),
        parse_point_json(rb, path.add_key("rb")),
      )
    _ => raise @json.JsonDecodeError((path, "bounds should be {lt,rb}"))
  }
}

///|
fn parse_int_like(
  json : Json,
  path : @json.JsonPath,
  field : String,
  default? : Int = 0,
) -> Int raise @json.JsonDecodeError {
  match json {
    Object(obj) =>
      match obj.get(field) {
        Some(Number(v, ..)) => v.to_int()
        Some(String(raw)) =>
          @string.parse_int(raw) catch {
            _ =>
              raise @json.JsonDecodeError(
                (path.add_key(field), "invalid int-like value"),
              )
          }
        Some(_) =>
          raise @json.JsonDecodeError(
            (path.add_key(field), "invalid int-like value"),
          )
        None => default
      }
    _ => raise @json.JsonDecodeError((path, "expect object"))
  }
}

///|
pub impl @json.FromJson for MxMobAnimNode with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMobAnimNode must be an object"))
  }
  let path_key = match root.get("path_key") {
    Some(String(v)) => v
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("path_key"), "missing path_key"),
      )
  }
  let total_duration_ms = match root.get("total_duration_ms") {
    Some(Number(v, ..)) => v.to_int()
    Some(String(raw)) =>
      @string.parse_int(raw) catch {
        _ =>
          raise @json.JsonDecodeError(
            (path.add_key("total_duration_ms"), "invalid total_duration_ms"),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("total_duration_ms"), "missing total_duration_ms"),
      )
  }
  let loop_ = match root.get("loop_") {
    Some(True) => true
    Some(False) => false
    _ => raise @json.JsonDecodeError((path.add_key("loop_"), "missing loop_"))
  }
  let first_head = match root.get("first_head") {
    Some(Null) | None => None
    Some(v) => Some(parse_point_json(v, path.add_key("first_head")))
  }
  let first_bounds = match root.get("first_bounds") {
    Some(Null) | None => None
    Some(v) => Some(parse_rect_json(v, path.add_key("first_bounds")))
  }
  { path_key, total_duration_ms, loop_, first_head, first_bounds }
}

///|
pub impl @json.FromJson for MxMobEffectNode with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMobEffectNode must be an object"))
  }
  let path_key = match root.get("path_key") {
    Some(String(v)) => v
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("path_key"), "missing path_key"),
      )
  }
  let z = parse_int_like(json, path, "z", default=0)
  let is_area_warning = match root.get("is_area_warning") {
    Some(True) => true
    Some(False) | None => false
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("is_area_warning"), "invalid is_area_warning"),
      )
  }
  { path_key, z, is_area_warning }
}

///|
pub impl @json.FromJson for MxMobAttackInfo with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMobAttackInfo must be an object"))
  }
  let type_ = parse_int_like(json, path, "type", default=0)
  let con_mp = parse_int_like(json, path, "conMP", default=0)
  let magic = match root.get("magic") {
    Some(Number(1.0, ..)) | Some(True) => true
    Some(Number(_, ..)) | Some(False) | None => false
    Some(String(raw)) => raw == "1" || raw == "true"
    _ => false
  }
  let range = match (root.get("lt"), root.get("rb")) {
    (Some(lt), Some(rb)) =>
      Some(
        Rectangle(
          parse_point_json(lt, path.add_key("lt")),
          parse_point_json(rb, path.add_key("rb")),
        ),
      )
    _ => None
  }
  { range, type_, con_mp, magic }
}

///|
pub impl @json.FromJson for MxMobAttackNode with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMobAttackNode must be an object"))
  }
  let id = parse_int_like(json, path, "id")
  let info : MxMobAttackInfo = @json.from_json(
    root.get("info").unwrap_or(Json::empty_object()),
    path=path.add_key("info"),
  )
  let animation_path_key = match root.get("animation_path_key") {
    Some(String(v)) => v
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("animation_path_key"), "missing animation_path_key"),
      )
  }
  let effects : Array[MxMobEffectNode] = match root.get("effects") {
    Some(Array(items)) =>
      items.map(item => @json.from_json(item, path=path.add_key("effects")))
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("effects"), "effects should be array"),
      )
    None => []
  }
  { id, info, animation_path_key, effects }
}

///|
pub impl @json.FromJson for MxMobSkillNode with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMobSkillNode must be an object"))
  }
  let skill_id = parse_int_like(json, path, "skill_id")
  let action = parse_int_like(json, path, "action")
  let animation_path_key = match root.get("animation_path_key") {
    Some(String(v)) => v
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("animation_path_key"), "missing animation_path_key"),
      )
  }
  let effects : Array[MxMobEffectNode] = match root.get("effects") {
    Some(Array(items)) =>
      items.map(item => @json.from_json(item, path=path.add_key("effects")))
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("effects"), "effects should be array"),
      )
    None => []
  }
  { skill_id, action, animation_path_key, effects }
}

///|
pub impl @json.FromJson for MxMob with fn from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "MxMob must be an object"))
  }
  let info : MobInfo = @json.from_json(
    root.get("info").unwrap_or(Json::null()),
    path=path.add_key("info"),
  )

  let stance_nodes : Map[String, MxMobAnimNode] = Map([])
  match root.get("stance_nodes") {
    Some(Object(obj)) =>
      for key, value in obj {
        stance_nodes[key] = @json.from_json(
          value,
          path=path.add_key("stance_nodes").add_key(key),
        )
      }
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("stance_nodes"), "stance_nodes should be object"),
      )
    None => ()
  }

  let attack_nodes : Map[Int, MxMobAttackNode] = Map([])
  match root.get("attack_nodes") {
    Some(Object(obj)) =>
      for key, value in obj {
        let id = @string.parse_int(key) catch {
          _ =>
            raise @json.JsonDecodeError(
              (
                path.add_key("attack_nodes").add_key(key),
                "invalid attack id key",
              ),
            )
        }
        attack_nodes[id] = @json.from_json(
          value,
          path=path.add_key("attack_nodes").add_key(key),
        )
      }
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("attack_nodes"), "attack_nodes should be object"),
      )
    None => ()
  }

  let skill_nodes : Map[Int, MxMobSkillNode] = Map([])
  match root.get("skill_nodes") {
    Some(Object(obj)) =>
      for key, value in obj {
        let id = @string.parse_int(key) catch {
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("skill_nodes").add_key(key), "invalid skill id key"),
            )
        }
        skill_nodes[id] = @json.from_json(
          value,
          path=path.add_key("skill_nodes").add_key(key),
        )
      }
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("skill_nodes"), "skill_nodes should be object"),
      )
    None => ()
  }

  let animations_path = match root.get("animations_path") {
    Some(String(value)) => value
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("animations_path"), "missing animations_path"),
      )
  }

  { info, stance_nodes, attack_nodes, skill_nodes, animations_path }
}
