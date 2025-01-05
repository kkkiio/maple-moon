///|
pub(all) enum Opcode {
  /// Login 1
  LOGIN_RESULT
  SERVER_STATUS
  SERVER_LIST
  CHAR_LIST
  SERVER_IP
  CHARNAME_RESPONSE
  ADD_NEWCHAR_ENTRY
  DELCHAR_RESPONSE
  PING

  /// Login 2
  RECOMMENDED_WORLDS
  CHECK_SPW_RESULT

  /// Inventory 1
  MODIFY_INVENTORY

  /// Player 2
  CHANGE_CHANNEL
  CHANGE_STATS
  GIVE_BUFF
  CANCEL_BUFF
  RECALCULATE_STATS
  UPDATE_SKILL
  FAME_RESPONSE

  /// Messaging 1
  SHOW_STATUS_INFO

  /// Inventory 2
  GATHER_RESULT
  SORT_RESULT

  /// Player 3

  /// Messaging 2
  SERVER_MESSAGE
  WEEK_EVENT_MESSAGE
  SKILL_MACROS
  SET_FIELD
  WHISPER
  FIELD_EFFECT

  /// MapObject
  SPAWN_CHAR
  REMOVE_CHAR

  /// Messaging
  CHAT_RECEIVED
  SCROLL_RESULT

  /// MapObject
  SPAWN_PET
  CHAR_MOVED

  /// Attack
  ATTACKED_CLOSE
  ATTACKED_RANGED
  ATTACKED_MAGIC
  UPDATE_CHARLOOK
  SHOW_FOREIGN_EFFECT
  GIVE_FOREIGN_BUFF
  CANCEL_FOREIGN_BUFF
  SHOW_ITEM_GAIN_INCHAT

  /// Player
  ADD_COOLDOWN

  /// MapObject
  SPAWN_MOB
  KILL_MOB
  SPAWN_MOB_C
  MOB_MOVED
  MOB_MOVE_RESPONSE
  APPLY_MONSTER_STATUS
  CANCEL_MONSTER_STATUS
  SHOW_MOB_HP
  SPAWN_NPC
  SPAWN_NPC_C
  SET_NPC_SCRIPTABLE
  DROP_LOOT
  REMOVE_LOOT
  HIT_REACTOR
  SPAWN_REACTOR
  REMOVE_REACTOR

  /// NPC Interaction
  NPC_DIALOGUE
  OPEN_NPC_SHOP
  CONFIRM_SHOP_TRANSACTION
  KEYMAP

  /// Player Interaction
  CHAR_INFO
  PLAYER_INTERACTION

  /// Cash Shop
  SET_CASH_SHOP
} derive(Eq, Compare, Show)

///|
pub fn int_value(self : Opcode) -> Int {
  match self {
    /// Login 1
    LOGIN_RESULT => 0
    SERVER_STATUS => 3
    SERVER_LIST => 10
    CHAR_LIST => 0x0B
    SERVER_IP => 12
    CHARNAME_RESPONSE => 13
    ADD_NEWCHAR_ENTRY => 14
    DELCHAR_RESPONSE => 15
    PING => 17

    /// Login 2
    RECOMMENDED_WORLDS => 27
    CHECK_SPW_RESULT => 28

    /// Inventory 1
    MODIFY_INVENTORY => 29

    /// Player 2
    CHANGE_CHANNEL => 16
    CHANGE_STATS => 31
    GIVE_BUFF => 32
    CANCEL_BUFF => 33
    RECALCULATE_STATS => 35
    UPDATE_SKILL => 36
    FAME_RESPONSE => 38

    /// Messaging 1
    SHOW_STATUS_INFO => 39

    /// Inventory 2
    GATHER_RESULT => 52
    SORT_RESULT => 53

    /// Player 3

    /// Messaging 2
    SERVER_MESSAGE => 68
    WEEK_EVENT_MESSAGE => 77
    SKILL_MACROS => 124
    SET_FIELD => 125
    WHISPER => 135
    FIELD_EFFECT => 138

    /// MapObject
    SPAWN_CHAR => 160
    REMOVE_CHAR => 161

    /// Messaging
    CHAT_RECEIVED => 162
    SCROLL_RESULT => 167

    /// MapObject
    SPAWN_PET => 168
    CHAR_MOVED => 185

    /// Attack
    ATTACKED_CLOSE => 186
    ATTACKED_RANGED => 187
    ATTACKED_MAGIC => 188
    UPDATE_CHARLOOK => 197
    SHOW_FOREIGN_EFFECT => 198
    GIVE_FOREIGN_BUFF => 199
    CANCEL_FOREIGN_BUFF => 200
    SHOW_ITEM_GAIN_INCHAT => 206 // TODO: Rename this (Terribly named)

    /// Player
    ADD_COOLDOWN => 234

    /// MapObject
    SPAWN_MOB => 236
    KILL_MOB => 237
    SPAWN_MOB_C => 238
    MOB_MOVED => 239
    MOB_MOVE_RESPONSE => 240
    APPLY_MONSTER_STATUS => 242
    CANCEL_MONSTER_STATUS => 243
    SHOW_MOB_HP => 250
    SPAWN_NPC => 257
    SPAWN_NPC_C => 259
    SET_NPC_SCRIPTABLE => 263
    DROP_LOOT => 268
    REMOVE_LOOT => 269
    HIT_REACTOR => 277
    SPAWN_REACTOR => 279
    REMOVE_REACTOR => 280

    /// NPC Interaction
    NPC_DIALOGUE => 304
    OPEN_NPC_SHOP => 305
    CONFIRM_SHOP_TRANSACTION => 306
    KEYMAP => 335

    /// Player Interaction
    CHAR_INFO => 61
    PLAYER_INTERACTION => 314

    /// Cash Shop
    SET_CASH_SHOP => 127
  }
}

///|
pub fn Opcode::from_int(v : Int) -> Opcode!UnknownOpCodeError {
  match v {
    /// Login 1
    0 => LOGIN_RESULT
    3 => SERVER_STATUS
    10 => SERVER_LIST
    11 => CHAR_LIST
    12 => SERVER_IP
    13 => CHARNAME_RESPONSE
    14 => ADD_NEWCHAR_ENTRY
    15 => DELCHAR_RESPONSE
    17 => PING

    /// Login 2
    27 => RECOMMENDED_WORLDS
    28 => CHECK_SPW_RESULT

    /// Inventory 1
    29 => MODIFY_INVENTORY

    /// Player 2
    16 => CHANGE_CHANNEL
    31 => CHANGE_STATS
    32 => GIVE_BUFF
    33 => CANCEL_BUFF
    35 => RECALCULATE_STATS
    36 => UPDATE_SKILL
    38 => FAME_RESPONSE

    /// Messaging 1
    39 => SHOW_STATUS_INFO

    /// Inventory 2
    52 => GATHER_RESULT
    53 => SORT_RESULT

    /// Player 3

    /// Messaging 2
    68 => SERVER_MESSAGE
    77 => WEEK_EVENT_MESSAGE
    124 => SKILL_MACROS
    125 => SET_FIELD
    135 => WHISPER
    138 => FIELD_EFFECT

    /// MapObject
    160 => SPAWN_CHAR
    161 => REMOVE_CHAR

    /// Messaging
    162 => CHAT_RECEIVED
    167 => SCROLL_RESULT

    /// MapObject
    168 => SPAWN_PET
    185 => CHAR_MOVED

    /// Attack
    186 => ATTACKED_CLOSE
    187 => ATTACKED_RANGED
    188 => ATTACKED_MAGIC
    197 => UPDATE_CHARLOOK
    198 => SHOW_FOREIGN_EFFECT
    199 => GIVE_FOREIGN_BUFF
    200 => CANCEL_FOREIGN_BUFF
    206 => SHOW_ITEM_GAIN_INCHAT // TODO: Rename this (Terribly named)

    /// Player
    234 => ADD_COOLDOWN

    /// MapObject
    236 => SPAWN_MOB
    237 => KILL_MOB
    238 => SPAWN_MOB_C
    239 => MOB_MOVED
    240 => MOB_MOVE_RESPONSE
    242 => APPLY_MONSTER_STATUS
    243 => CANCEL_MONSTER_STATUS
    250 => SHOW_MOB_HP
    257 => SPAWN_NPC
    259 => SPAWN_NPC_C
    263 => SET_NPC_SCRIPTABLE
    268 => DROP_LOOT
    269 => REMOVE_LOOT
    277 => HIT_REACTOR
    279 => SPAWN_REACTOR
    280 => REMOVE_REACTOR

    /// NPC Interaction
    304 => NPC_DIALOGUE
    305 => OPEN_NPC_SHOP
    306 => CONFIRM_SHOP_TRANSACTION
    335 => KEYMAP

    /// Player Interaction
    61 => CHAR_INFO
    314 => PLAYER_INTERACTION

    /// Cash Shop
    127 => SET_CASH_SHOP
    _ => raise UnknownOpCodeError(v)
  }
}

///|
type! UnknownOpCodeError Int

///|
pub fn hash(self : Opcode) -> Int {
  self.int_value()
}

///|
pub fn hash_combine(self : Opcode, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}
