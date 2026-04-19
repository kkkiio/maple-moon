///|
/// A wrapper struct for Json to show it as serialized string in the log.
pub(all) struct JsonValue(Json)

///|
pub impl Debug for JsonValue with to_repr(self) {
  Repr::literal(self.0.stringify())
}

///|
pub(all) struct HexInt(Int)

///|
pub impl Debug for HexInt with to_repr(self) {
  Repr::integer(@utils.to_hex_string(self.0.reinterpret_as_uint()))
}
