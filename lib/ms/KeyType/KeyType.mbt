pub enum Id {
  NONE
  SKILL
  ITEM
  CASH
  MENU
  ACTION
  FACE
  MACRO
  TEXT
} derive(Eq)

pub let values : FixedArray[Id] = [
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

pub fn get_type_by_id(id : Int) -> Id {
  if id <= Id::NONE.int_value() || id >= values.length() {
    return Id::NONE
  }
  values[id]
}

pub fn int_value(self : Id) -> Int {
  values.search(self).unwrap()
}

fn hash(self : Id) -> Int {
  self.int_value()
}
