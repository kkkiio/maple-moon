///|
pub(all) struct SpendAPMessage {
  stat_id : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for SpendAPMessage with type_code() {
  ClientOpcode::SPEND_AP.int_value()
}
