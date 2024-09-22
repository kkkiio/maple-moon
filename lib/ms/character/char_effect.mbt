// Character effects from Effect.wz
pub enum CharEffectId {
  LEVEL_UP
  JOB_CHANGE
  SCROLL_SUCCESS
  SCROLL_FAILURE
  MONSTER_CARD
} derive(Eq, Hash)

let paths : Map[CharEffectId, String] = Map::from_array(
  [
    (LEVEL_UP, "LevelUp"),
    (JOB_CHANGE, "JobChanged"),
    (SCROLL_SUCCESS, "Enchant/Success"),
    (SCROLL_FAILURE, "Enchant/Failure"),
    (MONSTER_CARD, "MonsterBook/cardGet"),
  ],
)
