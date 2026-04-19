///|
pub(all) struct SpendSPMessage {
  skill_id : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for SpendSPMessage with type_code() {
  ClientOpcode::SPEND_SP.int_value()
}

///|
pub(all) struct UseSPResetMessage {
  slot_no : Int
  item_id : Int
  to : Int
  from : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for UseSPResetMessage with type_code() {
  ClientOpcode::USE_CASH_ITEM.int_value()
}
