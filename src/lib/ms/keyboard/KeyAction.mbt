///| Maple-specific keycodes sent via the Keymap Packet.
pub(all) enum BasicActionId {
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
} derive(Show, Eq, Compare, ToJson, FromJson)

///|
pub fn int_value(self : BasicActionId) -> Int {
  match self {
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
pub impl Hash for BasicActionId with hash_combine(self, hasher) {
  hasher.combine(self.int_value())
}

///|
pub fn BasicActionId::from_int(id : Int) -> BasicActionId? {
  match id {
    1 => Some(BasicActionId::EQUIPMENT)
    2 => Some(BasicActionId::ITEMS)
    3 => Some(BasicActionId::STATS)
    4 => Some(BasicActionId::SKILLS)
    5 => Some(BasicActionId::FRIENDS)
    6 => Some(BasicActionId::WORLD_MAP)
    7 => Some(BasicActionId::MAPLE_CHAT)
    8 => Some(BasicActionId::MINI_MAP)
    9 => Some(BasicActionId::QUEST_LOG)
    10 => Some(BasicActionId::KEY_BINDINGS)
    11 => Some(BasicActionId::TOGGLE_CHAT)
    12 => Some(BasicActionId::WHISPER)
    13 => Some(BasicActionId::SAY)
    14 => Some(BasicActionId::PARTY_CHAT)
    15 => Some(BasicActionId::MENU)
    16 => Some(BasicActionId::QUICK_SLOTS)
    18 => Some(BasicActionId::GUILD)
    19 => Some(BasicActionId::FRIENDS_CHAT)
    20 => Some(BasicActionId::PARTY)
    21 => Some(BasicActionId::NOTIFIER)
    24 => Some(BasicActionId::CASHSHOP)
    25 => Some(BasicActionId::GUILD_CHAT)
    28 => Some(BasicActionId::MEDALS)
    29 => Some(BasicActionId::BITS)
    30 => Some(BasicActionId::ALLIANCE_CHAT)
    31 => Some(BasicActionId::MAPLE_NEWS)
    32 => Some(BasicActionId::MANAGE_LEGION)
    33 => Some(BasicActionId::PROFESSION)
    34 => Some(BasicActionId::BOSS_PARTY)
    35 => Some(BasicActionId::ITEM_POT)
    36 => Some(BasicActionId::EVENT)
    37 => Some(BasicActionId::SILENT_CRUSADE)
    38 => Some(BasicActionId::BATTLE_ANALYSIS)
    39 => Some(BasicActionId::GUIDE)
    40 => Some(BasicActionId::VIEWERS_CHAT)
    41 => Some(BasicActionId::ENHANCE_EQUIP)
    42 => Some(BasicActionId::MONSTER_COLLECTION)
    43 => Some(BasicActionId::SOUL_WEAPON)
    44 => Some(BasicActionId::CHAR_INFO)
    45 => Some(BasicActionId::CHANGE_CHANNEL)
    46 => Some(BasicActionId::MAIN_MENU)
    47 => Some(BasicActionId::SCREENSHOT)
    48 => Some(BasicActionId::PICTURE_MODE)
    49 => Some(BasicActionId::MAPLE_ACHIEVEMENT)
    51 => Some(BasicActionId::PICKUP)
    52 => Some(BasicActionId::SIT)
    53 => Some(BasicActionId::ATTACK)
    54 => Some(BasicActionId::JUMP)
    55 => Some(BasicActionId::INTERACT_HARVEST)
    56 => Some(BasicActionId::MAPLE_STORAGE)
    57 => Some(BasicActionId::SAFE_MODE)
    58 => Some(BasicActionId::MUTE)
    59 => Some(BasicActionId::MONSTER_BOOK)
    60 => Some(BasicActionId::TO_SPOUSE)
    100 => Some(BasicActionId::FACE1)
    101 => Some(BasicActionId::FACE2)
    102 => Some(BasicActionId::FACE3)
    103 => Some(BasicActionId::FACE4)
    104 => Some(BasicActionId::FACE5)
    105 => Some(BasicActionId::FACE6)
    106 => Some(BasicActionId::FACE7)
    107 => Some(BasicActionId::LEFT)
    108 => Some(BasicActionId::RIGHT)
    109 => Some(BasicActionId::UP)
    110 => Some(BasicActionId::DOWN)
    111 => Some(BasicActionId::BACK)
    112 => Some(BasicActionId::TAB)
    113 => Some(BasicActionId::RETURN)
    114 => Some(BasicActionId::ESCAPE)
    115 => Some(BasicActionId::SPACE)
    116 => Some(BasicActionId::DELETE)
    117 => Some(BasicActionId::HOME)
    118 => Some(BasicActionId::END)
    119 => Some(BasicActionId::COPY)
    120 => Some(BasicActionId::PASTE)
    _ => None
  }
}

///|
pub fn BasicActionId::name(self : BasicActionId) -> String {
  self.to_json().as_object().unwrap().get("$tag").unwrap().as_string().unwrap()
}

///|
pub fn BasicActionId::from_name(name : String) -> BasicActionId raise {
  @json.from_json({ "$tag": name.to_json() })
}
