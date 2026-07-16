///|
fn LocalServer::on_change_map(self : LocalServer, json : Json) -> Unit raise {
  let change_map_message : ChangeMapMessage = @json.from_json(json)
  let source_map_id = self.last_map_id
  @io_service.execute_background(
    fn() raise {
      guard get_target_by_map_id_and_portal_name(
          source_map_id,
          change_map_message.target_p,
        )
        is Some({ tm, tn }) else {
        @log.error("portal target not found", data={
          "map_id": source_map_id,
          "portal_name": change_map_message.target_p,
        })
        return
      }
      guard get_portal_id_by_map_id_and_portal_name(tm, tn) is Some(portal_id) else {
        @log.error("target portal not found", data={ "tm": tm, "tn": tn })
        return
      }
      self.last_map_id = tm
      self.last_portal_id = portal_id
      self.save_character_core_snapshot()
      let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
        map_id=tm,
        portal_id~,
      )
      self.send_server_message(set_field_message)
      self.spawn_mobs_for_map(tm)
    },
    on_error=fn(error) {
      @log.error("failed to load change-map resource closure", data={
        "source_map_id": source_map_id,
        "portal_name": change_map_message.target_p,
        "error": error.to_string(),
      })
      abort(
        "failed to load change-map resource closure: map_id=\{source_map_id}, portal=\{change_map_message.target_p}, error=\{error}",
      )
    },
  )
}

///|
fn get_target_by_map_id_and_portal_name(
  map_id : Int,
  portal_name : String,
) -> PortalTarget? raise {
  guard load_tiled_map_by_map_id(map_id) is Some(map) else { return None }
  let portals = require_portal_layer(map)
  for portal in portals.objects {
    let pn = tiled_object_string_required(portal, "pn")
    if pn == portal_name {
      let tm = tiled_object_int_required(portal, "tm")
      let tn = tiled_object_string_required(portal, "tn")
      return Some({ tm, tn })
    }
  }
  None
}

///|
priv struct PortalTarget {
  tm : Int
  tn : String
}

///|
fn get_portal_id_by_map_id_and_portal_name(
  map_id : Int,
  portal_name : String,
) -> Int? raise {
  guard load_tiled_map_by_map_id(map_id) is Some(map) else { return None }
  let portals = require_portal_layer(map)
  for idx, portal in portals.objects {
    let pn = tiled_object_string_required(portal, "pn")
    if pn == portal_name {
      return Some(idx)
    }
  }
  None
}

///|
fn require_portal_layer(map : @tiled.TiledMap) -> @tiled.TiledObjectLayer {
  match map.object_layer("portal") {
    Some(layer) => layer
    None => abort("missing `portal` layer in map.tmj")
  }
}

///|
fn load_tiled_map_by_map_id(map_id : Int) -> @tiled.TiledMap? raise {
  if map_id <= 0 {
    return None
  }

  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let mx_address = "res://Map/Map\{prefix}/\{strid}.img.mx.json"
  let (_tiled_path, tiled_map) = @res.load_tiled_map_from_mx(mx_address)
  Some(tiled_map)
}

///|
fn tiled_object_string_required(
  obj : @tiled.TiledObject,
  name : String,
) -> String {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::String(value)) => value
    Some(_) =>
      abort("object property '\{name}' must be string, object_id=\{obj.id}")
    None => abort("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn tiled_object_int_required(obj : @tiled.TiledObject, name : String) -> Int {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => value
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int()
    Some(_) =>
      abort("object property '\{name}' must be int, object_id=\{obj.id}")
    None => abort("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn tiled_object_int_like_required(
  obj : @tiled.TiledObject,
  name : String,
) -> Int {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => value
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int()
    Some(@tiled.TiledPropertyValue::String(value)) =>
      @string.parse_int(value) catch {
        _ =>
          abort(
            "object property '\{name}' must be int-like string, object_id=\{obj.id}",
          )
      }
    Some(_) =>
      abort("object property '\{name}' must be int-like, object_id=\{obj.id}")
    None => abort("missing object property '\{name}', object_id=\{obj.id}")
  }
}

///|
fn tiled_object_int_or_default(
  obj : @tiled.TiledObject,
  name : String,
  default_ : Int,
) -> Int {
  match obj.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => value
    Some(@tiled.TiledPropertyValue::Float(value)) => value.to_int()
    Some(_) =>
      abort("object property '\{name}' must be int, object_id=\{obj.id}")
    None => default_
  }
}

///|
fn require_life_layer(map : @tiled.TiledMap) -> @tiled.TiledObjectLayer {
  match map.object_layer("life") {
    Some(layer) => layer
    None => abort("missing `life` layer in map.tmj")
  }
}
