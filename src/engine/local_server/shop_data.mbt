///|
priv struct NpcShopDatabase {
  by_npc_id : Map[Int, @server_proto.OpenNpcShopMessage]
}

///|
fn NpcShopDatabase::from_map(
  by_npc_id : Map[Int, @server_proto.OpenNpcShopMessage],
) -> NpcShopDatabase {
  { by_npc_id, }
}

///|
fn NpcShopDatabase::get_shop_by_npc_id(
  self : NpcShopDatabase,
  npc_id : Int,
) -> @server_proto.OpenNpcShopMessage? {
  self.by_npc_id.get(npc_id)
}

///|
fn LocalServer::get_shop_by_npc_id(
  self : LocalServer,
  npc_id : Int,
) -> @server_proto.OpenNpcShopMessage? {
  match self.npc_shop_db {
    Some(db) => db.get_shop_by_npc_id(npc_id)
    None => None
  }
}

///|
fn LocalServer::load_npc_shop_database(self : LocalServer) -> Unit {
  @io_service.execute_background(fn() {
    let by_npc_id = @shop_sheet.load_npc_shop_map()
    self.npc_shop_db = Some(NpcShopDatabase::from_map(by_npc_id))
    @log.info("Loaded shops.tsv and shopitems.tsv", data=Map([]))
  })
}
