///|
pub struct NxMob {
  info : MobInfo
  meta : NxMobMeta
  skills : Map[Int, NxMobSkillEntry]
  attacks : Map[Int, NxMobAttackEntry]
  animations : Map[StanceType, MobAnimation]
}

///|
pub struct NxMobMeta {
  can_move : Bool
  can_jump : Bool
  can_fly : Bool
} derive(ToJson)

///|
pub struct NxMobSkillEntry {
  skill_id : Int
  action : Int
  animation : MobAnimation
}

///|
pub struct NxMobAttackEntry {
  id : Int
  info : NxMobAttackInfo
  animation : MobAnimation
}

///|
pub struct NxMobAttackInfo {
  range : @struct.Rectangle[Int]?
  type_ : Int
  con_mp : Int
  magic : Bool
  effects : Array[NxMobEffect]
}

///|
pub impl @json.FromJson for NxMobAttackInfo with from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "NxMobAttackInfo must be an object"))
  }
  let type_ = match root.get("type") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
  let con_mp = match root.get("conMP") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
  let magic = match root.get("magic") {
    Some(Number(1.0, ..)) => true
    _ => false
  }
  let range = parse_rect(json)
  let effects = Array::new()
  if root.contains("areaWarning") {
    match root.get("areaWarning") {
      Some(v) => effects.push(parse_effect(v, true)) catch { _ => () }
      None => ()
    }
  }

  // Parse standard effects
  match root.get("effect") {
    Some(v) => effects.push(parse_effect(v, false)) catch { _ => () }
    None => ()
  }
  let mut no = 0
  while true {
    let key = "effect" + no.to_string()
    match root.get(key) {
      Some(v) => {
        effects.push(parse_effect(v, false)) catch {
          _ => ()
        }
        no += 1
      }
      None => break
    }
  }
  { range, type_, con_mp, magic, effects }
}

///|
pub struct NxMobEffect {
  animation : MobAnimation
  z : Int
  is_area_warning : Bool
}

///|
fn parse_effect(json : Json, is_area_warning : Bool) -> NxMobEffect raise {
  let animation = load_animation(json)
  let z = match json {
    Object(o) =>
      match o.get("z") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
    _ => 0
  }
  { animation, z, is_area_warning }
}

///|
fn parse_rect(json : Json) -> @struct.Rectangle[Int]? {
  match json {
    Object(o) => {
      let lt_opt = o.get("lt")
      let rb_opt = o.get("rb")
      match (lt_opt, rb_opt) {
        (Some(lt_json), Some(rb_json)) => {
          let lt = parse_point(lt_json)
          let rb = parse_point(rb_json)
          Some(@struct.Rectangle::new(lt, rb))
        }
        _ => None
      }
    }
    _ => None
  }
}

///|
fn parse_point(json : Json) -> @struct.Point[Int] {
  match json {
    Array([Number(x, ..), Number(y, ..)]) => { x: x.to_int(), y: y.to_int() }
    _ => { x: 0, y: 0 }
  }
}

///|
pub impl @json.FromJson for NxMob with from_json(json, path) {
  guard json is Object(root) else {
    raise @json.JsonDecodeError((path, "NxMob must be an object"))
  }

  // 1. Parse Info
  let info_json = match root.get("info") {
    Some(v) => v
    None => Json::null()
  }
  let info : MobInfo = @json.from_json(info_json, path=path.add_key("info"))

  // 2. Parse Standard Animations
  let animations = load_animations(json) catch { _ => Map::new() }

  // 3. Parse Attacks
  let attacks : Map[Int, NxMobAttackEntry] = Map::new()
  for key, value in root {
    if key.has_prefix("attack") {
      try {
        let suffix = key[6:] // remove "attack"
        let id = @string.parse_int(suffix)
        // check children count > 0 equivalent
        let has_children = match value {
          Object(o) => o.length() > 0
          _ => false
        }
        if has_children {
          let animation = load_animation(value)
          let info = match value {
            Object(o) => o.get("info").unwrap_or(Json::null())
            _ => Json::null()
          }
          let info_parsed : NxMobAttackInfo = @json.from_json(info) catch {
            // If info is missing or invalid, use default.
            // Note: empty info allows animation to play but no hit box/damage?
            _ => { range: None, type_: 0, con_mp: 0, magic: false, effects: [] }
          }
          attacks.set(id, { id, info: info_parsed, animation })
        }
      } catch {
        _ => ()
      }
    }
  }

  // 4. Parse Skills
  let skills : Map[Int, NxMobSkillEntry] = Map::new()
  match root.get("info") {
    Some(Object(info_obj)) =>
      match info_obj.get("skill") {
        Some(Object(skill_node)) =>
          for _key, val in skill_node {
            try {
              // skill node structure: "0": { "skill": 123, "action": 1, "level": ... }
              guard val is Object(sk_obj) else { continue }
              let skill_id = match sk_obj.get("skill") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }
              let action = match sk_obj.get("action") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }

              // Load animation from "skill{action}"
              let annot_key = "skill" + action.to_string()
              let animation = match root.get(annot_key) {
                Some(v) => load_animation(v)
                None => load_animation(Json::null())
              }
              skills.set(skill_id, { skill_id, action, animation })
            } catch {
              _ => ()
            }
          }
        _ => ()
      }
    _ => ()
  }

  // 5. Meta capabilities
  let has_jump = root.contains("jump")
  let has_fly = root.contains("fly")
  let has_move = root.contains("move")
  let can_fly = has_fly // Assuming children count check implies existence
  let can_jump = has_jump
  let can_move = has_move || can_fly
  { info, meta: { can_move, can_jump, can_fly }, skills, attacks, animations }
}
