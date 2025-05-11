///|
pub fn make_show_status_info_handler(
  sub_handler_factory_map : Map[Int, @game_mod.SubRouteHandler]
) -> (@net.Opcode, (@net.InPacket) -> Unit) {
  @net.make_handler(
    @net.SHOW_STATUS_INFO,
    parse_show_status_info!(_, sub_handler_factory_map),
    fn(sub_handler) { sub_handler.handle() },
    log_recv=true,
  )
}

///|
pub fn parse_show_status_info(
  recv : @net.InPacket,
  sub_handler_factory_map : Map[Int, @game_mod.SubRouteHandler]
) -> &@game_mod.SubRouteAction! {
  let sub_id = recv.read_byte!()
  guard sub_handler_factory_map.get(sub_id) is Some(sub_handler_factory) else {
    fail!("Unknown sub_id: \{sub_id}")
  }
  sub_handler_factory!(recv)
}
