///|
pub fn from_tiled_life_spawns(map : @tiled.TiledMap) -> Array[NxLife] raise {
  guard map.object_layer("life") is Some(layer) else { return [] }
  let lives = []
  for obj in layer.objects {
    let x = obj.x.to_int()
    let y = obj.y.to_int()
    lives.push({
      cy: maptiled_object_int_required(obj, "cy"),
      f: maptiled_object_int_optional(obj, "f").unwrap_or(0),
      fh: maptiled_object_int_required(obj, "fh"),
      hide: maptiled_object_int_optional(obj, "hide").unwrap_or(0),
      id: maptiled_object_stringish_required(obj, "id"),
      mob_time: maptiled_object_int_optional(obj, "mobTime"),
      rx0: maptiled_object_int_required(obj, "rx0"),
      rx1: maptiled_object_int_required(obj, "rx1"),
      type_: maptiled_object_string_required(obj, "type"),
      x,
      y,
    })
  }
  lives
}

///|
pub fn from_tiled_foothold_tree(
  map : @tiled.TiledMap,
) -> @physics.NxFootholdTree raise {
  guard map.object_layer("foothold") is Some(layer) else {
    fail("missing `foothold` layer in map.tmj")
  }
  let tree : Map[Int, Map[Int, Map[Int, @physics.NxFoothold]]] = Map::new()
  for obj in layer.objects {
    guard obj.polyline.length() >= 2 else {
      fail("foothold object must contain polyline with 2 points, id=\{obj.id}")
    }
    if obj.polyline.length() != 2 {
      fail("foothold polyline must have exactly 2 points, id=\{obj.id}")
    }
    let p1 = obj.polyline[0]
    let p2 = obj.polyline[1]
    let foothold_id = maptiled_object_int_required(obj, "id")
    let layer_id = maptiled_object_int_required(obj, "layer")
    let group_id = maptiled_object_int_required(obj, "group")
    let prev = maptiled_object_int_required(obj, "prev")
    let next = maptiled_object_int_required(obj, "next")
    let x1 = (obj.x + p1.x).to_int()
    let y1 = (obj.y + p1.y).to_int()
    let x2 = (obj.x + p2.x).to_int()
    let y2 = (obj.y + p2.y).to_int()
    let groups = tree.get_or_init(layer_id, fn() { Map::new() })
    let footholds = groups.get_or_init(group_id, fn() { Map::new() })
    if footholds.contains(foothold_id) {
      fail("duplicate foothold id=\{foothold_id}")
    }
    footholds.set(foothold_id, { prev, next, x1, x2, y1, y2 })
  }
  validate_foothold_refs(tree)
  @physics.NxFootholdTree(tree)
}

///|
fn validate_foothold_refs(
  tree : Map[Int, Map[Int, Map[Int, @physics.NxFoothold]]],
) -> Unit raise {
  let ids = Set::new()
  for _, groups in tree {
    for _, footholds in groups {
      for id, _ in footholds {
        ids.add(id)
      }
    }
  }
  for _, groups in tree {
    for _, footholds in groups {
      for id, foothold in footholds {
        if foothold.prev != 0 && !ids.contains(foothold.prev) {
          fail("foothold id=\{id} has invalid prev=\{foothold.prev}")
        }
        if foothold.next != 0 && !ids.contains(foothold.next) {
          fail("foothold id=\{id} has invalid next=\{foothold.next}")
        }
      }
    }
  }
}

///|
let tiled_root_ref : Ref[@entity.Entity?] = Ref::new(None)

///|
let tiled_background_motion_states_ref : Ref[
  Map[@entity.Entity, TiledBackgroundMotionState],
] = Ref::new(Map::new())

///|
priv struct TiledBackgroundMotionState {
  base_offset : @selene_math.Vec2D
  velocity : @selene_math.Vec2D
}

///|
fn tiled_property_int_optional(
  layer : @tiled.TiledLayer,
  name : String,
) -> Int? {
  match layer.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(@tiled.TiledPropertyValue::String(value)) => {
      let parsed = try? @string.parse_int(value)
      match parsed {
        Ok(parsed) => Some(parsed)
        Err(_) => None
      }
    }
    Some(_) => None
    None => None
  }
}

///|
fn reload_tiled_background_motion_states(root : @entity.Entity) -> Unit {
  let states : Map[@entity.Entity, TiledBackgroundMotionState] = Map::new()
  for pair in @tiled.tiled_image_layer_instances().to_array() {
    let layer_entity = pair.0
    let instance = pair.1
    if instance.map_entity != root {
      continue
    }
    let layer = instance.layer
    let background_type = tiled_property_int_optional(layer, "type")
    guard background_type is Some(background_type) else { continue }
    if background_type != 4 && background_type != 5 {
      continue
    }
    let vx = tiled_property_int_optional(layer, "cx").unwrap_or(0).to_double()
    let vy = tiled_property_int_optional(layer, "cy").unwrap_or(0).to_double()
    states[layer_entity] = {
      base_offset: @selene_math.Vec2D(layer.offset_x, layer.offset_y),
      velocity: @selene_math.Vec2D(vx, vy),
    }
  }
  tiled_background_motion_states_ref.val = states
}

///|
pub fn set_tiled_map(map : @tiled.TiledMap) -> Unit {
  let root = match tiled_root_ref.val {
    Some(root) => root
    None => {
      let root = @entity.Entity::new()
      tiled_root_ref.val = Some(root)
      root
    }
  }
  @tiled.respawn_tiled_map_into_entity(root, map)
  reload_tiled_background_motion_states(root)
}

///|
pub fn clear_tiled_map() -> Unit {
  tiled_background_motion_states_ref.val = Map::new()
  match tiled_root_ref.val {
    Some(root) => {
      @tiled.despawn_tiled_tree(root)
      tiled_root_ref.val = None
    }
    None => ()
  }
}

///|
/// Updates Maple moving backgrounds (`type4`/`type5`) exported as Tiled imagelayers.
pub fn tiled_background_motion_system(_world : @ecs.World) -> Unit {
  if tiled_background_motion_states_ref.val.is_empty() {
    return
  }
  let delta = @time.delta()
  for pair in tiled_background_motion_states_ref.val.to_array() {
    let layer_entity = pair.0
    let state = pair.1
    let next_offset = @selene_math.Vec2D(
      state.base_offset[@selene_math.X] + state.velocity[@selene_math.X] * delta,
      state.base_offset[@selene_math.Y] + state.velocity[@selene_math.Y] * delta,
    )
    tiled_background_motion_states_ref.val.set(layer_entity, {
      ..state,
      base_offset: next_offset,
    })
    @transform2d.set_xy(layer_entity, next_offset)
  }
}

///|
fn maptiled_object_string_required(
  obj : @tiled.TiledObject,
  name : String,
) -> String raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(_) =>
      fail("object property '\{name}' must be string, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn maptiled_object_stringish_required(
  obj : @tiled.TiledObject,
  name : String,
) -> String raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(@tiled.TiledPropertyValue::Int(value)) => value.to_string()
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int().to_string()
    Some(_) =>
      fail("object property '\{name}' must be string/int, object_id=\{obj.id}")
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn maptiled_object_int_optional(
  obj : @tiled.TiledObject,
  name : String,
) -> Int? raise {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(_) =>
      fail("object property '\{name}' must be int, object_id=\{obj.id}")
    None => None
  }
}

///|
fn maptiled_object_int_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Int raise {
  match maptiled_object_int_optional(obj, name) {
    Some(value) => value
    None => fail("missing object property '\{name}', object_id=\{obj.id}")
  }
}
