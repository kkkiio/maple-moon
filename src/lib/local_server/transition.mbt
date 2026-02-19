///|
fn LocalServer::on_change_map(self : LocalServer, json : Json) -> Unit raise {
  let change_map_message : ChangeMapMessage = @json.from_json(json)
  @io_service.execute_background(async fn() {
    guard get_target_by_map_id_and_portal_name(
        self.last_map_id,
        change_map_message.target_p,
      )
      is Some({ tm, tn }) else {
      @log.error("portal target not found", data={
        "map_id": self.last_map_id,
        "portal_name": change_map_message.target_p,
      })
      return
    }
    guard get_portal_id_by_map_id_and_portal_name(tm, tn) is Some(portal_id) else {
      @log.error("target portal not found", data={ "tm": tm, "tn": tn })
      return
    }
    self.last_map_id = tm
    if self.db is Some(db) {
      db.save_character_data({ "character_id": 1.0, "map_id": tm.to_double() })
    }
    let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
      map_id=tm,
      portal_id~,
    )
    self.last_portal_id = portal_id
    self.send_server_message(set_field_message)
    self.spawn_mobs_for_map(tm)
  })
}

///|
async fn get_target_by_map_id_and_portal_name(
  map_id : Int,
  portal_name : String,
) -> PortalTarget? {
  if map_id <= 0 {
    return None
  }
  let loader = get_mapx_loader()
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  let node = loader.load_res_async(path)
  guard node.value() is { "portal": Object(portals), .. } else { return None }
  for _, portal in portals {
    if portal
      is { "pn": String(pn), "tm": Number(tm, ..), "tn": String(tn), .. } &&
      pn == portal_name {
      return Some({ tm: tm.to_int(), tn })
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
async fn get_portal_id_by_map_id_and_portal_name(
  map_id : Int,
  portal_name : String,
) -> Int? {
  if map_id <= 0 {
    return None
  }
  let loader = get_mapx_loader()
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  let node = loader.load_res_async(path)
  guard node.value() is { "portal": Object(portals), .. } else { return None }
  for id_str, portal in portals {
    if portal is { "pn": String(pn), .. } && pn == portal_name {
      return Some(@strconv.parse_int(id_str))
    }
  }
  None
}
