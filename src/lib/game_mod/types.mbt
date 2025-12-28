///|
pub type StatHandler = (Int) -> Bool

///|
pub type SubRouteHandler = (@net.InPacket) -> &SubRouteAction raise

///|
pub(open) trait SubRouteAction: Show {
  handle(Self) -> Unit
}
