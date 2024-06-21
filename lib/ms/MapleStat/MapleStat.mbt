pub enum Id {
  SKIN
  FACE
  HAIR
  LEVEL
  JOB
  STR
  DEX
  INT
  LUK
  HP
  MAXHP
  MP
  MAXMP
  AP
  SP
  EXP
  FAME
  MESO
  PET
  GACHAEXP
} derive(Eq)

pub fn int_value(self : Id) -> Int {
  match self {
    SKIN => 0
    FACE => 1
    HAIR => 2
    LEVEL => 3
    JOB => 4
    STR => 5
    DEX => 6
    INT => 7
    LUK => 8
    HP => 9
    MAXHP => 10
    MP => 11
    MAXMP => 12
    AP => 13
    SP => 14
    EXP => 15
    FAME => 16
    MESO => 17
    PET => 18
    GACHAEXP => 19
  }
}

pub fn hash(self : Id) -> Int {
  self.int_value()
}

pub let values : FixedArray[Id] = [
  SKIN,
  FACE,
  HAIR,
  LEVEL,
  JOB,
  STR,
  DEX,
  INT,
  LUK,
  HP,
  MAXHP,
  MP,
  MAXMP,
  AP,
  SP,
  EXP,
  FAME,
  MESO,
  PET,
  GACHAEXP,
]

pub fn by_id(id : Int) -> Id {
  values[id]
}

pub let codes : @immut/hashmap.Map[Id, Int] = @immut/hashmap.from_array(
  [
    (Id::SKIN, 0x1),
    (Id::FACE, 0x2),
    (Id::HAIR, 0x4),
    (Id::LEVEL, 0x10),
    (Id::JOB, 0x20),
    (Id::STR, 0x40),
    (Id::DEX, 0x80),
    (Id::INT, 0x100),
    (Id::LUK, 0x200),
    (Id::HP, 0x400),
    (Id::MAXHP, 0x800),
    (Id::MP, 0x1000),
    (Id::MAXMP, 0x2000),
    (Id::AP, 0x4000),
    (Id::SP, 0x8000),
    (Id::EXP, 0x10000),
    (Id::FAME, 0x20000),
    (Id::MESO, 0x40000),
    (Id::PET, 0x180008),
    (Id::GACHAEXP, 0x200000),
  ],
)
