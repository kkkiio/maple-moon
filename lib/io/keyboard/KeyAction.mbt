// Maple-specific keycodes sent via the Keymap Packet.
///|
pub(all) enum ActionId {
  NONE
  EQUIPMENT
  ITEMS
  STATS
  SKILLS
  FRIENDS
  WORLD_MAP
  MAPLE_CHAT
  MINI_MAP
  QUEST_LOG
  KEY_BINDINGS
  TOGGLE_CHAT
  WHISPER
  SAY
  PARTY_CHAT
  MENU
  QUICK_SLOTS
  GUILD
  FRIENDS_CHAT
  PARTY
  NOTIFIER
  CASHSHOP
  GUILD_CHAT
  MEDALS
  BITS
  ALLIANCE_CHAT
  MAPLE_NEWS
  MANAGE_LEGION
  PROFESSION
  BOSS_PARTY
  ITEM_POT
  EVENT
  SILENT_CRUSADE
  BATTLE_ANALYSIS
  GUIDE
  VIEWERS_CHAT
  ENHANCE_EQUIP
  MONSTER_COLLECTION
  SOUL_WEAPON
  CHAR_INFO
  CHANGE_CHANNEL
  MAIN_MENU
  SCREENSHOT
  PICTURE_MODE
  MAPLE_ACHIEVEMENT
  PICKUP
  SIT
  ATTACK
  JUMP
  INTERACT_HARVEST
  MAPLE_STORAGE
  SAFE_MODE
  MUTE
  MONSTER_BOOK
  TO_SPOUSE
  FACE1
  FACE2
  FACE3
  FACE4
  FACE5
  FACE6
  FACE7
  // Static keys
  LEFT
  RIGHT
  UP
  DOWN
  BACK
  TAB
  RETURN
  ESCAPE
  SPACE
  DELETE
  HOME
  END
  COPY
  PASTE
} derive(Show, Eq, Compare)

///|
pub fn int_value(self : ActionId) -> Int {
  match self {
    NONE => 0
    EQUIPMENT => 1
    ITEMS => 2
    STATS => 3
    SKILLS => 4
    FRIENDS => 5
    WORLD_MAP => 6
    MAPLE_CHAT => 7
    MINI_MAP => 8
    QUEST_LOG => 9
    KEY_BINDINGS => 10
    TOGGLE_CHAT => 11
    WHISPER => 12
    SAY => 13
    PARTY_CHAT => 14
    MENU => 15
    QUICK_SLOTS => 16
    GUILD => 18
    FRIENDS_CHAT => 19
    PARTY => 20
    NOTIFIER => 21
    CASHSHOP => 24
    GUILD_CHAT => 25
    MEDALS => 28
    BITS => 29
    ALLIANCE_CHAT => 30
    MAPLE_NEWS => 31
    MANAGE_LEGION => 32
    PROFESSION => 33
    BOSS_PARTY => 34
    ITEM_POT => 35
    EVENT => 36
    SILENT_CRUSADE => 37
    BATTLE_ANALYSIS => 38
    GUIDE => 39
    VIEWERS_CHAT => 40
    ENHANCE_EQUIP => 41
    MONSTER_COLLECTION => 42
    SOUL_WEAPON => 43
    CHAR_INFO => 44
    CHANGE_CHANNEL => 45
    MAIN_MENU => 46
    SCREENSHOT => 47
    PICTURE_MODE => 48
    MAPLE_ACHIEVEMENT => 49
    PICKUP => 51
    SIT => 52
    ATTACK => 53
    JUMP => 54
    INTERACT_HARVEST => 55
    MAPLE_STORAGE => 56
    SAFE_MODE => 57
    MUTE => 58
    MONSTER_BOOK => 59
    TO_SPOUSE => 60
    FACE1 => 100
    FACE2 => 101
    FACE3 => 102
    FACE4 => 103
    FACE5 => 104
    FACE6 => 105
    FACE7 => 106
    LEFT => 107
    RIGHT => 108
    UP => 109
    DOWN => 110
    BACK => 111
    TAB => 112
    RETURN => 113
    ESCAPE => 114
    SPACE => 115
    DELETE => 116
    HOME => 117
    END => 118
    COPY => 119
    PASTE => 120
  }
}

///|
pub fn hash(self : ActionId) -> Int {
  self.int_value()
}

///|
pub fn hash_combine(self : ActionId, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub fn get_action_by_id(id : Int) -> ActionId!@utils.UnknownEnum {
  match id {
    0 => ActionId::NONE
    1 => ActionId::EQUIPMENT
    2 => ActionId::ITEMS
    3 => ActionId::STATS
    4 => ActionId::SKILLS
    5 => ActionId::FRIENDS
    6 => ActionId::WORLD_MAP
    7 => ActionId::MAPLE_CHAT
    8 => ActionId::MINI_MAP
    9 => ActionId::QUEST_LOG
    10 => ActionId::KEY_BINDINGS
    11 => ActionId::TOGGLE_CHAT
    12 => ActionId::WHISPER
    13 => ActionId::SAY
    14 => ActionId::PARTY_CHAT
    15 => ActionId::MENU
    16 => ActionId::QUICK_SLOTS
    18 => ActionId::GUILD
    19 => ActionId::FRIENDS_CHAT
    20 => ActionId::PARTY
    21 => ActionId::NOTIFIER
    24 => ActionId::CASHSHOP
    25 => ActionId::GUILD_CHAT
    28 => ActionId::MEDALS
    29 => ActionId::BITS
    30 => ActionId::ALLIANCE_CHAT
    31 => ActionId::MAPLE_NEWS
    32 => ActionId::MANAGE_LEGION
    33 => ActionId::PROFESSION
    34 => ActionId::BOSS_PARTY
    35 => ActionId::ITEM_POT
    36 => ActionId::EVENT
    37 => ActionId::SILENT_CRUSADE
    38 => ActionId::BATTLE_ANALYSIS
    39 => ActionId::GUIDE
    40 => ActionId::VIEWERS_CHAT
    41 => ActionId::ENHANCE_EQUIP
    42 => ActionId::MONSTER_COLLECTION
    43 => ActionId::SOUL_WEAPON
    44 => ActionId::CHAR_INFO
    45 => ActionId::CHANGE_CHANNEL
    46 => ActionId::MAIN_MENU
    47 => ActionId::SCREENSHOT
    48 => ActionId::PICTURE_MODE
    49 => ActionId::MAPLE_ACHIEVEMENT
    51 => ActionId::PICKUP
    52 => ActionId::SIT
    53 => ActionId::ATTACK
    54 => ActionId::JUMP
    55 => ActionId::INTERACT_HARVEST
    56 => ActionId::MAPLE_STORAGE
    57 => ActionId::SAFE_MODE
    58 => ActionId::MUTE
    59 => ActionId::MONSTER_BOOK
    60 => ActionId::TO_SPOUSE
    100 => ActionId::FACE1
    101 => ActionId::FACE2
    102 => ActionId::FACE3
    103 => ActionId::FACE4
    104 => ActionId::FACE5
    105 => ActionId::FACE6
    106 => ActionId::FACE7
    107 => ActionId::LEFT
    108 => ActionId::RIGHT
    109 => ActionId::UP
    110 => ActionId::DOWN
    111 => ActionId::BACK
    112 => ActionId::TAB
    113 => ActionId::RETURN
    114 => ActionId::ESCAPE
    115 => ActionId::SPACE
    116 => ActionId::DELETE
    117 => ActionId::HOME
    118 => ActionId::END
    119 => ActionId::COPY
    120 => ActionId::PASTE
    _ => raise @utils.UnknownEnum(id)
  }
}
