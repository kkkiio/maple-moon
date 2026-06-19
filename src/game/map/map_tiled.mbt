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
  let tree : Map[Int, Map[Int, Map[Int, @physics.NxFoothold]]] = Map([])
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
    let groups = tree.get_or_init(layer_id, fn() { Map([]) })
    let footholds = groups.get_or_init(group_id, fn() { Map([]) })
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
  let ids = Set([])
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
let tiled_root_world_stores : Map[UInt, @entity.Entity] = Map([])

///|
let tiled_object_spawn_reader : Ref[
  @event.EventReader[@tiled.TiledObjectSpawnedEvent],
] = Ref(@event.EventReader())

///|
let tiled_image_layer_spawn_reader : Ref[
  @event.EventReader[@tiled.TiledImageLayerSpawnedEvent],
] = Ref(@event.EventReader())

///|
fn tiled_object_int_optional_soft(
  obj : @tiled.TiledObject,
  name : String,
) -> Int? {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(@tiled.TiledPropertyValue::String(value)) =>
      Some(@string.parse_int(value)) catch {
        _ => None
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
  Some((@string.parse_int(parts[1]), parts[2].to_owned())) catch {
    _ => None
  }
}

///|
fn set_entity_z(entity : @entity.Entity, z : Int) -> Unit {
  match @transform.transforms().get(entity) {
    Some(current) =>
      @transform.transforms().set(entity, {
        ..current,
        translation: @selene_math.Vec3(
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
  if parse_background_index(event.layer.name, "background_back_") is Some(index) {
    set_entity_z(event.object_entity, @graphics.BACKGROUND_ZINDEX + index)
    return
  }
  if parse_background_index(event.layer.name, "background_front_")
    is Some(index) {
    set_entity_z(event.object_entity, @graphics.FOREGROUND_ZINDEX + index)
    return
  }
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
pub fn set_tiled_map(
  world : @ecs.World,
  map : @tiled.TiledMap,
  background_animations? : Map[String, @resource.SeleneClip] = {},
) -> Unit raise {
  let root = tiled_root_world_stores.get_or_init(world.id, fn() {
    @entity.Entity()
  })
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
  set_tiled_backgrounds(
    world, map, root, image_layer_events, background_animations,
  )
}

///|
pub fn clear_tiled_map(world : @ecs.World) -> Unit {
  clear_tiled_backgrounds(world)
  if tiled_root_world_stores.get(world.id) is Some(root) {
    @tiled.despawn_tiled_tree(root)
    tiled_root_world_stores.remove(world.id)
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
