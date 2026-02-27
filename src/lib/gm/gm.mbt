///|
fn send_set_meso(meso : Int) -> Unit {
  @game_server.send(@server_proto.AdminCommandMessage::SetMeso(meso~))
}

///|
fn send_add_item(item_id : Int, quantity : Int) -> Unit {
  @game_server.send(
    @server_proto.AdminCommandMessage::AddItem(item_id~, quantity~),
  )
}

///|
fn send_warp(map_id : Int, portal_id : Int) -> Unit {
  @game_server.send(
    @server_proto.AdminCommandMessage::Warp(map_id~, portal_id~),
  )
}

///|
extern "js" fn install_gm_bindings(
  set_meso : (Int) -> Unit,
  add_item : (Int, Int) -> Unit,
  warp : (Int, Int) -> Unit,
) -> Unit =
  #| (setMeso, addItem, warpTo) => {
  #|   const toInt = (value, fallback) => {
  #|     const n = Number(value);
  #|     return Number.isFinite(n) ? Math.trunc(n) : fallback;
  #|   };
  #|
  #|   globalThis.$gm = {
  #|     help() {
  #|       console.info("$gm.meso(amount)");
  #|       console.info("$gm.item(itemId, qty = 1)");
  #|       console.info("$gm.warp(mapId, portalId = 0)");
  #|     },
  #|     meso(amount) {
  #|       setMeso(toInt(amount, 0));
  #|     },
  #|     item(itemId, qty = 1) {
  #|       addItem(toInt(itemId, 0), toInt(qty, 1));
  #|     },
  #|     warp(mapId, portalId = 0) {
  #|       warpTo(toInt(mapId, 0), toInt(portalId, 0));
  #|     },
  #|   };
  #| };

///|
/// Register `$gm` commands on `globalThis` for local debug usage.
pub fn install() -> Unit {
  install_gm_bindings(send_set_meso, send_add_item, send_warp)
}
