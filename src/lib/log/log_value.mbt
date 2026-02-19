///|
/// A wrapper struct for Json to show it as serialized string in the log.
pub(all) struct JsonValue(Json)

///|
pub impl Show for JsonValue with output(self, logger) {
  logger.write_string(self.0.stringify())
}

///|
pub(all) struct HexInt(Int)

///|
pub impl Show for HexInt with output(self, logger) {
  logger.write_string(@utils.to_hex_string(self.0.reinterpret_as_uint()))
}
