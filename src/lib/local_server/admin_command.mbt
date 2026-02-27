///|
fn LocalServer::on_admin_command(self : LocalServer, json : Json) -> Unit raise {
  let msg : @server_proto.AdminCommandMessage = @json.from_json(json)
  match msg {
    SetMeso(meso~) => {
      self.player_meso = if meso > 0 { meso } else { 0 }
      self.save_character_core_snapshot()
      self.send_server_message(@server_proto.ChangeStatsMesoMessage::{
        meso: self.player_meso,
      })
    }
    AddItem(item_id~, quantity~) => {
      if quantity <= 0 {
        return
      }
      if self.add_item_to_inventory(item_id, quantity) {
        self.save_character_inventory_snapshot()
      }
    }
    Warp(map_id~, portal_id~) => {
      if map_id <= 0 {
        return
      }
      let target_portal_id = if portal_id >= 0 { portal_id } else { 0 }
      self.last_map_id = map_id
      self.last_portal_id = target_portal_id
      self.save_character_core_snapshot()
      self.send_server_message(
        @server_proto.SetFieldMessage::ChangeMap(
          map_id~,
          portal_id=target_portal_id,
        ),
      )
      self.spawn_mobs_for_map(map_id)
    }
  }
}
