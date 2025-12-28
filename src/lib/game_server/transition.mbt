///|
fn LocalServer::on_change_map(self : LocalServer, json : Json) -> Unit raise {
  let change_map_message : ChangeMapMessage = @json.from_json(json)
  @io_service.execute_background(async fn() {
    guard get_target_by_map_id_and_portal_name(
        self.last_map_id,
        change_map_message.target_p,
      )
      is Some({ tm, tn }) else {
      @log.error(
        {
          "map_id": self.last_map_id,
          "portal_name": change_map_message.target_p,
        },
        "portal target not found",
      )
      return
    }
    guard get_portal_id_by_map_id_and_portal_name(tm, tn) is Some(portal_id) else {
      @log.error({ "tm": tm, "tn": tn }, "target portal not found")
      return
    }
    self.last_map_id = tm
    let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
      map_id=tm,
      portal_id~,
    )
    self.last_portal_id = portal_id
    default_server.send_server_message(set_field_message)

    // spawn mobs
    @io_service.execute_background(async fn() {
      let loader = get_mapx_loader()
      let prefix = (tm / 100000000).to_string()
      let strid = @utils.stoi_left_pad0(tm, 9)
      let path = ["Map\{prefix}", "\{strid}.img"]
      let node_res = loader.load_res_async(path)
      guard node_res.value() is { "life": Object(life_map), .. } else { return }
      for _, entity in life_map {
        match entity {
          {
            "type": String("m"),
            "id": String(id_str),
            "x": Number(x, ..),
            "y": Number(y, ..),
            "f": Number(f, ..),
            "fh": Number(fh, ..),
            ..
          } => {
            let monster_id = @strconv.parse_int(id_str)
            self.last_object_id += 1
            let spawn_msg = MobSpawnMessage::{
              oid: self.last_object_id,
              id: monster_id,
              x: x.to_int(),
              y: y.to_int(),
              stance: f.to_int(),
              fh: fh.to_int(),
              team: -1,
            }
            default_server.send_server_message(spawn_msg)

            // Initialize server-side mob state
            let mob_loader = @resource.get_mob_loader()
            let mob_strid = @utils.stoi_left_pad0(monster_id, 7)
            let mob_path = ["\{mob_strid}.img"]
            let mob_node = mob_loader.load_res_async(mob_path)
            guard mob_node.value()
              is { "info": { "maxHP": Number(max_hp, ..), .. }, .. } else {
              return
            }
            let server_mob = ServerMob::{
              oid: spawn_msg.oid,
              id: monster_id,
              hp: max_hp.to_int(),
              max_hp: max_hp.to_int(),
            }
            self.mobs.set(spawn_msg.oid, server_mob)
          }
          _ => ()
        }
      }
    })
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

///|
using @maple_protocol {type MobSpawnMessage}
