///|
pub(all) struct SpendAPMessage {
  stat_id : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for SpendAPMessage with fn type_code() {
  ClientOpcode::SPEND_AP.int_value()
}
