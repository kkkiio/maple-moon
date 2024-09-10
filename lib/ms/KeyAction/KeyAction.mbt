// Maple-specific keycodes sent via the Keymap Packet.
pub enum Id {
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

pub fn int_value(self : Id) -> Int {
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

pub fn hash(self : Id) -> Int {
  self.int_value()
}

pub fn hash_combine(self : Id, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub fn get_action_by_id(id : Int) -> Id!@utils.UnknownEnum {
  match id {
    0 => Id::NONE
    1 => Id::EQUIPMENT
    2 => Id::ITEMS
    3 => Id::STATS
    4 => Id::SKILLS
    5 => Id::FRIENDS
    6 => Id::WORLD_MAP
    7 => Id::MAPLE_CHAT
    8 => Id::MINI_MAP
    9 => Id::QUEST_LOG
    10 => Id::KEY_BINDINGS
    11 => Id::TOGGLE_CHAT
    12 => Id::WHISPER
    13 => Id::SAY
    14 => Id::PARTY_CHAT
    15 => Id::MENU
    16 => Id::QUICK_SLOTS
    18 => Id::GUILD
    19 => Id::FRIENDS_CHAT
    20 => Id::PARTY
    21 => Id::NOTIFIER
    24 => Id::CASHSHOP
    25 => Id::GUILD_CHAT
    28 => Id::MEDALS
    29 => Id::BITS
    30 => Id::ALLIANCE_CHAT
    31 => Id::MAPLE_NEWS
    32 => Id::MANAGE_LEGION
    33 => Id::PROFESSION
    34 => Id::BOSS_PARTY
    35 => Id::ITEM_POT
    36 => Id::EVENT
    37 => Id::SILENT_CRUSADE
    38 => Id::BATTLE_ANALYSIS
    39 => Id::GUIDE
    40 => Id::VIEWERS_CHAT
    41 => Id::ENHANCE_EQUIP
    42 => Id::MONSTER_COLLECTION
    43 => Id::SOUL_WEAPON
    44 => Id::CHAR_INFO
    45 => Id::CHANGE_CHANNEL
    46 => Id::MAIN_MENU
    47 => Id::SCREENSHOT
    48 => Id::PICTURE_MODE
    49 => Id::MAPLE_ACHIEVEMENT
    51 => Id::PICKUP
    52 => Id::SIT
    53 => Id::ATTACK
    54 => Id::JUMP
    55 => Id::INTERACT_HARVEST
    56 => Id::MAPLE_STORAGE
    57 => Id::SAFE_MODE
    58 => Id::MUTE
    59 => Id::MONSTER_BOOK
    60 => Id::TO_SPOUSE
    100 => Id::FACE1
    101 => Id::FACE2
    102 => Id::FACE3
    103 => Id::FACE4
    104 => Id::FACE5
    105 => Id::FACE6
    106 => Id::FACE7
    107 => Id::LEFT
    108 => Id::RIGHT
    109 => Id::UP
    110 => Id::DOWN
    111 => Id::BACK
    112 => Id::TAB
    113 => Id::RETURN
    114 => Id::ESCAPE
    115 => Id::SPACE
    116 => Id::DELETE
    117 => Id::HOME
    118 => Id::END
    119 => Id::COPY
    120 => Id::PASTE
    _ => raise @utils.UnknownEnum(id)
  }
}
