///|
fn LocalServer::on_change_map(self : LocalServer, json : Json) -> Unit raise {
  let change_map_message : ChangeMapMessage = @json.from_json(json)
  @io_service.execute_background(async fn() {
    guard get_portal_id_by_map_id_and_portal_name(
        self.last_map_id,
        change_map_message.target_p,
      )
      is Some(portal_id) else {
      @log.error(
        {
          "map_id": change_map_message.target_id,
          "portal_name": change_map_message.target_p,
        },
        "portal not found",
      )
      return
    }
    self.last_map_id = change_map_message.target_id
    let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
      map_id=change_map_message.target_id,
      portal_id~,
    )
    self.last_portal_id = portal_id
    let set_field_json = set_field_message.to_json()
    default_server.server_message_queue.push(
      (@net.Opcode::SET_FIELD.int_value(), set_field_json),
    )
  })
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
  let portals = node["portal"]
  for portal in portals.iter() {
    if portal["pn"].get_string() == portal_name {
      let id_str = portal.name()
      return Some(@strconv.parse_int(id_str))
    }
  }
  None
}
