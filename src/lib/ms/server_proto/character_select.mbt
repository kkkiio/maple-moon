/// Messages for character selection and creation.

///|
const LOCAL_OPCODE_CHARACTER_LIST = 0x5000

///|
const LOCAL_OPCODE_CREATE_CHARACTER_RESULT = 0x5001

///|
/// Request the current character list from local server.
pub(all) struct CharacterListRequestMessage(Unit) derive (
  Show,
  Default,
  ToJson,
  FromJson,
)

///|
pub impl ClientMessage for CharacterListRequestMessage with type_code() {
  @net.ClientOpcode::CHAR_LIST_REQUEST.int_value()
}

///|
/// Request creation of a new explorer character.
pub(all) struct CreateCharacterMessage {
  /// Desired character name.
  name : String
  /// Job id for the created character.
  job : Int
  /// Selected face id.
  face : Int
  /// Selected hair id without color offset.
  hair : Int
  /// Selected hair color offset.
  hairc : Int
  /// Selected skin id.
  skin : Int
  /// Selected top equip id.
  top : Int
  /// Selected bottom equip id.
  bot : Int
  /// Selected shoes equip id.
  shoes : Int
  /// Selected weapon equip id.
  weapon : Int
  /// Whether the character is female.
  female : Bool
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for CreateCharacterMessage with type_code() {
  @net.ClientOpcode::CREATE_CHAR.int_value()
}

///|
/// One selectable character entry shown in character select UI.
pub(all) struct CharacterListEntry {
  /// Stable local character id.
  character_id : Int
  /// Display name.
  name : String
  /// Character look used by preview UI.
  look : @char_look.LookEntry
} derive(Show, ToJson, FromJson)

///|
/// Local-server character list response.
pub(all) struct CharacterListMessage {
  /// Available characters for the current local account.
  characters : Array[CharacterListEntry]
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for CharacterListMessage with type_code() {
  LOCAL_OPCODE_CHARACTER_LIST
}

///|
/// Local-server response for character creation.
pub(all) struct CreateCharacterResultMessage {
  /// Whether character creation succeeded.
  success : Bool
  /// Newly created character entry when successful.
  character : CharacterListEntry?
  /// Error text when creation failed.
  error : String?
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for CreateCharacterResultMessage with type_code() {
  LOCAL_OPCODE_CREATE_CHARACTER_RESULT
}
