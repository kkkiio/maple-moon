/// Messages for character selection and creation.

///|
const LOCAL_OPCODE_CHARACTER_LIST = 0x5000

///|
const LOCAL_OPCODE_CREATE_CHARACTER_RESULT = 0x5001

///|
/// Request the current character list from local server.
pub(all) struct CharacterListRequestMessage(Unit) derive (
  Debug,
  Default,
  ToJson,
  FromJson,
)

///|
pub impl ClientMessage for CharacterListRequestMessage with fn type_code() {
  ClientOpcode::CHAR_LIST_REQUEST.int_value()
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
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for CreateCharacterMessage with fn type_code() {
  ClientOpcode::CREATE_CHAR.int_value()
}

///|
/// One selectable character entry shown in character select UI.
pub(all) struct CharacterListEntry {
  /// Stable local character id.
  character_id : Int
  /// Display name.
  name : String
  /// Character look used by preview UI.
  look : LookEntry
} derive(Debug, ToJson, FromJson)

///|
/// Local-server character list response.
pub(all) struct CharacterListMessage {
  /// Available characters for the current local account.
  characters : Array[CharacterListEntry]
} derive(Debug, ToJson, FromJson)

///|
/// Return the local character-list response opcode.
///
/// # Example
/// ```moonbit nocheck
/// inspect(CharacterListMessage::type_code(), content="20480")
/// ```
pub fn CharacterListMessage::type_code() -> Int {
  LOCAL_OPCODE_CHARACTER_LIST
}

///|
pub impl ServerMessage for CharacterListMessage with fn type_code() {
  CharacterListMessage::type_code()
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
} derive(Debug, ToJson, FromJson)

///|
/// Return the local character-creation result opcode.
///
/// # Example
/// ```moonbit nocheck
/// inspect(CreateCharacterResultMessage::type_code(), content="20481")
/// ```
pub fn CreateCharacterResultMessage::type_code() -> Int {
  LOCAL_OPCODE_CREATE_CHARACTER_RESULT
}

///|
pub impl ServerMessage for CreateCharacterResultMessage with fn type_code() {
  CreateCharacterResultMessage::type_code()
}

///|
pub(all) struct LookEntry {
  female : Bool
  skin : Int
  faceid : Int
  hairid : Int
  equips : Map[Int, Int]
  maskedequips : Map[Int, Int]
  petids : Array[Int]
} derive(Debug, ToJson, Default)

///|
pub impl @json.FromJson for LookEntry with fn from_json(json, path) {
  fn parse_int_map(
    value : Json,
    path : @json.JsonPath,
  ) -> Map[Int, Int] raise @json.JsonDecodeError {
    guard value is Object(obj) else {
      raise @json.JsonDecodeError((path, "expect object"))
    }
    let result = Map([])
    for key, item in obj {
      let slot_id = @string.parse_int(key) catch {
        _ => raise @json.JsonDecodeError((path.add_key(key), "invalid int key"))
      }
      let item_id : Int = @json.from_json(item, path=path.add_key(key))
      result.set(slot_id, item_id)
    }
    result
  }
  guard json
    is {
      "female": female,
      "skin": skin,
      "faceid": faceid,
      "hairid": hairid,
      "equips": equips,
      "maskedequips": maskedequips,
      "petids": petids,
      ..
    } else {
    raise @json.JsonDecodeError((path, "invalid LookEntry"))
  }
  {
    female: @json.from_json(female, path=path.add_key("female")),
    skin: @json.from_json(skin, path=path.add_key("skin")),
    faceid: @json.from_json(faceid, path=path.add_key("faceid")),
    hairid: @json.from_json(hairid, path=path.add_key("hairid")),
    equips: parse_int_map(equips, path.add_key("equips")),
    maskedequips: parse_int_map(maskedequips, path.add_key("maskedequips")),
    petids: @json.from_json(petids, path=path.add_key("petids")),
  }
}
