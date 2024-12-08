pub(all) enum KeyType {
  NONE
  SKILL
  ITEM
  CASH
  MENU
  ACTION
  FACE
  MACRO
  TEXT
} derive(Eq, Compare)

pub let values : FixedArray[KeyType] = [
  NONE,
  SKILL,
  ITEM,
  CASH,
  MENU,
  ACTION,
  FACE,
  MACRO,
  TEXT,
]

pub fn get_type_by_id(id : Int) -> KeyType {
  if id <= KeyType::NONE.int_value() || id >= values.length() {
    return KeyType::NONE
  }
  values[id]
}

pub fn int_value(self : KeyType) -> Int {
  values.search(self).unwrap()
}

fn hash(self : KeyType) -> Int {
  self.int_value()
}
