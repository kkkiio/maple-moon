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
let tiled_object_spawn_reader : Ref[
  @event.EventReader[@tiled.TiledObjectSpawnedEvent],
] = Ref::new(@event.EventReader::new())

///|
let tiled_image_layer_spawn_reader : Ref[
  @event.EventReader[@tiled.TiledImageLayerSpawnedEvent],
] = Ref::new(@event.EventReader::new())

///|
let maple_camera_y_offset = 80.0

///|
priv struct TiledBackgroundMotionState {
  base_screen_offset : @selene_math.Vec2D
  moving_world_pos : @selene_math.Vec2D
  ratio : @selene_math.Vec2D
  speed : @selene_math.Vec2D
  moving_axis : (Bool, Bool)
  repeat : (Bool, Bool)
  tile_step : @selene_math.Vec2D
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
fn is_background_image_layer(name : String) -> Bool {
  parse_background_index(name, "background_back_") is Some(_) ||
  parse_background_index(name, "background_front_") is Some(_)
}

///|
fn maple_background_move_speed(ratio : Int) -> Double {
  (ratio * @logic_fps.LOGIC_FPS).to_double() / 16.0
}

///|
fn maple_background_axis_mode(
  background_type : Int,
  axis : @selene_math.Axis,
  ratio : Int,
) -> (Bool, Double, Double) {
  if background_type == 4 && axis == @selene_math.X {
    return (true, 0.0, maple_background_move_speed(ratio))
  }
  if background_type == 5 && axis == @selene_math.Y {
    return (true, 0.0, maple_background_move_speed(ratio))
  }
  (false, ratio.to_double() / 100.0, 0.0)
}

///|
fn maple_background_axis_screen(
  camera_top_left : Double,
  view_half : Double,
  base_screen_offset : Double,
  moving_world_pos : Double,
  ratio : Double,
  moving : Bool,
) -> Double {
  if moving {
    return moving_world_pos - camera_top_left
  }
  base_screen_offset + ratio * (camera_top_left + view_half) + view_half
}

///|
fn wrap_tiled_screen(value : Double, step : Double) -> Double {
  if step <= 0.0 {
    return value
  }
  let mut wrapped = value
  while wrapped > 0.0 {
    wrapped -= step
  }
  while wrapped < -step {
    wrapped += step
  }
  wrapped
}

///|
fn tiled_object_int_optional_soft(
  obj : @tiled.TiledObject,
  name : String,
) -> Int? {
  match obj.property(name) {
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
fn parse_map_layer_name(name : String) -> (Int, String)? {
  let parts = name.split("_").to_array()
  if parts.length() != 3 || parts[0] != "layer" {
    return None
  }
  if parts[2] != "obj" && parts[2] != "tile" {
    return None
  }
  let parsed = try? @string.parse_int(parts[1])
  match parsed {
    Ok(layer) => Some((layer, parts[2].to_string()))
    Err(_) => None
  }
}

///|
fn parse_background_index(name : String, prefix : String) -> Int? {
  if !name.has_prefix(prefix) {
    return None
  }
  let suffix = name[prefix.length():name.length()].to_string()
  let parsed = try? @string.parse_int(suffix)
  match parsed {
    Ok(index) => Some(index)
    Err(_) => None
  }
}

///|
fn set_entity_z(entity : @entity.Entity, z : Int) -> Unit {
  match @transform.transforms().get(entity) {
    Some(current) =>
      @transform.transforms().set(entity, {
        ..current,
        translation: @selene_math.Vec3::new(
          current.translation.x,
          current.translation.y,
          z.to_double(),
        ),
      })
    None =>
      @transform.transforms().set(
        entity,
        @transform.Transform::from_xyz(0.0, 0.0, z.to_double()),
      )
  }
}

///|
fn apply_map_object_z(event : @tiled.TiledObjectSpawnedEvent) -> Unit {
  guard parse_map_layer_name(event.layer.name) is Some((layer_from_name, kind)) else {
    return
  }
  let layer = tiled_object_int_optional_soft(event.object, "layer").unwrap_or(
    layer_from_name,
  )
  let z = match kind {
    "obj" => {
      let z = tiled_object_int_optional_soft(event.object, "z").unwrap_or(0)
      let zM = tiled_object_int_optional_soft(event.object, "zM").unwrap_or(0)
      @graphics.map_obj_z(layer, z, zM)
    }
    "tile" => {
      let zM = tiled_object_int_optional_soft(event.object, "zM").unwrap_or(0)
      @graphics.map_tile_z(layer, zM)
    }
    _ => return
  }
  set_entity_z(event.object_entity, z)
}

///|
fn apply_map_image_layer_z(event : @tiled.TiledImageLayerSpawnedEvent) -> Unit {
  let name = event.layer.name
  let z = if parse_background_index(name, "background_back_") is Some(index) {
    @graphics.BACKGROUND_ZINDEX + index
  } else if parse_background_index(name, "background_front_") is Some(index) {
    @graphics.FOREGROUND_ZINDEX + index
  } else {
    return
  }
  set_entity_z(event.layer_entity, z)
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
    if !is_background_image_layer(layer.name) {
      continue
    }
    let background_type = tiled_property_int_optional(layer, "type")
    guard background_type is Some(background_type) else { continue }
    let rx = tiled_property_int_optional(layer, "rx").unwrap_or(0)
    let ry = tiled_property_int_optional(layer, "ry").unwrap_or(0)
    let cx = tiled_property_int_optional(layer, "cx").unwrap_or(0)
    let cy = tiled_property_int_optional(layer, "cy").unwrap_or(0)
    let image_width = instance.image_layer.image_width.unwrap_or(1).max(1)
    let image_height = instance.image_layer.image_height.unwrap_or(1).max(1)
    let step_x = if cx > 0 { cx } else { image_width }
    let step_y = if cy > 0 { cy } else { image_height }
    let x_mode = maple_background_axis_mode(background_type, @selene_math.X, rx)
    let y_mode = maple_background_axis_mode(background_type, @selene_math.Y, ry)
    states[layer_entity] = {
      base_screen_offset: @selene_math.Vec2D(layer.offset_x, layer.offset_y),
      moving_world_pos: @selene_math.Vec2D(layer.offset_x, layer.offset_y),
      ratio: @selene_math.Vec2D(x_mode.1, y_mode.1),
      speed: @selene_math.Vec2D(x_mode.2, y_mode.2),
      moving_axis: (x_mode.0, y_mode.0),
      repeat: (instance.image_layer.repeat_x, instance.image_layer.repeat_y),
      tile_step: @selene_math.Vec2D(step_x.to_double(), step_y.to_double()),
    }
  }
  tiled_background_motion_states_ref.val = states
}

///|
fn disable_selene_parallax_for_backgrounds(
  event : @tiled.TiledImageLayerSpawnedEvent,
) -> Unit {
  if is_background_image_layer(event.layer.name) {
    @tiled.tiled_parallax_layers().remove(event.layer_entity)
  }
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
  let spawn_settings = {
    ..@tiled.default_tiled_spawn_settings(),
    image_layer_hook: Some(disable_selene_parallax_for_backgrounds),
  }
  @tiled.respawn_tiled_map_into_entity(root, map, settings=spawn_settings)
  let object_events = @tiled.tiled_object_spawned_event_bus.read(
    tiled_object_spawn_reader.val,
  )
  for event in object_events {
    if event.map_entity == root {
      apply_map_object_z(event)
    }
  }
  let image_layer_events = @tiled.tiled_image_layer_spawned_event_bus.read(
    tiled_image_layer_spawn_reader.val,
  )
  for event in image_layer_events {
    if event.map_entity == root {
      apply_map_image_layer_z(event)
    }
  }
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
/// Updates Maple backgrounds exported as Tiled imagelayers using
/// OpenMapleClient-compatible coordinate formulas.
pub fn tiled_background_motion_system(_world : @ecs.World) -> Unit {
  if tiled_background_motion_states_ref.val.is_empty() {
    return
  }
  let delta = @time.delta()
  let camera_top_left = @camera.current_camera_top_left()
  let screen_size = @system.get_screen_size()
  let bottom_right = @camera.viewport_to_world(screen_size)
  let view_size = bottom_right - camera_top_left
  let view_half = @selene_math.Vec2D(
    view_size[@selene_math.X] * 0.5,
    view_size[@selene_math.Y] * 0.5,
  )
  let camera_for_formula = @selene_math.Vec2D(
    camera_top_left[@selene_math.X],
    camera_top_left[@selene_math.Y] - maple_camera_y_offset,
  )
  for pair in tiled_background_motion_states_ref.val.to_array() {
    let layer_entity = pair.0
    let state = pair.1
    let mut next_moving_world_x = state.moving_world_pos[@selene_math.X]
    if state.moving_axis.0 {
      next_moving_world_x += state.speed[@selene_math.X] * delta
    }
    let mut next_moving_world_y = state.moving_world_pos[@selene_math.Y]
    if state.moving_axis.1 {
      next_moving_world_y += state.speed[@selene_math.Y] * delta
    }
    let screen_x = maple_background_axis_screen(
      camera_for_formula[@selene_math.X],
      view_half[@selene_math.X],
      state.base_screen_offset[@selene_math.X],
      next_moving_world_x,
      state.ratio[@selene_math.X],
      state.moving_axis.0,
    )
    let screen_y = maple_background_axis_screen(
      camera_for_formula[@selene_math.Y],
      view_half[@selene_math.Y],
      state.base_screen_offset[@selene_math.Y],
      next_moving_world_y,
      state.ratio[@selene_math.Y],
      state.moving_axis.1,
    )
    let wrapped_screen_x = if state.repeat.0 {
      wrap_tiled_screen(screen_x, state.tile_step[@selene_math.X])
    } else {
      screen_x
    }
    let wrapped_screen_y = if state.repeat.1 {
      wrap_tiled_screen(screen_y, state.tile_step[@selene_math.Y])
    } else {
      screen_y
    }
    let world_pos = @selene_math.Vec2D(
      camera_top_left[@selene_math.X] + wrapped_screen_x,
      camera_top_left[@selene_math.Y] + wrapped_screen_y,
    )
    tiled_background_motion_states_ref.val.set(layer_entity, {
      ..state,
      moving_world_pos: @selene_math.Vec2D(
        next_moving_world_x, next_moving_world_y,
      ),
    })
    @transform2d.set_xy(layer_entity, world_pos)
  }
}

///|
test "background axis mode mapping covers type0~5" {
  let x0 = maple_background_axis_mode(0, @selene_math.X, -40)
  let y0 = maple_background_axis_mode(0, @selene_math.Y, -5)
  assert_false(x0.0)
  assert_false(y0.0)
  assert_eq(x0.1, -0.4)
  assert_eq(y0.1, -0.05)
  assert_eq(x0.2, 0.0)
  assert_eq(y0.2, 0.0)

  let x1 = maple_background_axis_mode(1, @selene_math.X, 30)
  let y1 = maple_background_axis_mode(1, @selene_math.Y, -20)
  assert_false(x1.0)
  assert_false(y1.0)
  assert_eq(x1.1, 0.3)
  assert_eq(y1.1, -0.2)

  let x2 = maple_background_axis_mode(2, @selene_math.X, 25)
  let y2 = maple_background_axis_mode(2, @selene_math.Y, -45)
  assert_false(x2.0)
  assert_false(y2.0)
  assert_eq(x2.1, 0.25)
  assert_eq(y2.1, -0.45)

  let x3 = maple_background_axis_mode(3, @selene_math.X, -70)
  let y3 = maple_background_axis_mode(3, @selene_math.Y, 10)
  assert_false(x3.0)
  assert_false(y3.0)
  assert_eq(x3.1, -0.7)
  assert_eq(y3.1, 0.1)

  let x4 = maple_background_axis_mode(4, @selene_math.X, -5)
  let y4 = maple_background_axis_mode(4, @selene_math.Y, -3)
  assert_true(x4.0)
  assert_false(y4.0)
  assert_eq(x4.1, 0.0)
  assert_eq(y4.1, -0.03)
  assert_true(x4.2 < 0.0)
  assert_eq(y4.2, 0.0)

  let x5 = maple_background_axis_mode(5, @selene_math.X, -7)
  let y5 = maple_background_axis_mode(5, @selene_math.Y, -9)
  assert_false(x5.0)
  assert_true(y5.0)
  assert_eq(x5.1, -0.07)
  assert_eq(y5.1, 0.0)
  assert_eq(x5.2, 0.0)
  assert_true(y5.2 < 0.0)
}

///|
test "parallax screen axis matches OpenMapleClient formula" {
  let screen_x = maple_background_axis_screen(
    1691.0, 400.0, -66.0, 0.0, -0.4, false,
  )
  let expected = -66.0 + -40.0 * (400.0 + 1691.0) / 100.0 + 400.0
  assert_true((screen_x - expected).abs() < 0.000001)

  let camera_top_left_y = 733.0
  let view_half_y = 300.0
  let screen_y = maple_background_axis_screen(
    camera_top_left_y - maple_camera_y_offset,
    view_half_y,
    -12.0,
    0.0,
    -0.5,
    false,
  )
  let expected_y = -12.0 +
    -50.0 * (view_half_y + camera_top_left_y - maple_camera_y_offset) / 100.0 +
    view_half_y
  assert_true((screen_y - expected_y).abs() < 0.000001)
}

///|
test "repeat wrap keeps value in [-step, 0]" {
  assert_eq(wrap_tiled_screen(150.0, 1024.0), -874.0)
  assert_eq(wrap_tiled_screen(-1400.0, 1024.0), -376.0)
  assert_eq(wrap_tiled_screen(0.0, 1024.0), 0.0)
  assert_eq(wrap_tiled_screen(-1024.0, 1024.0), -1024.0)
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
