///|
pub(all) enum BodyLayer {
  BODY_NONE
  BODY
  ARM
  ARM_BELOW_HEAD
  ARM_BELOW_HEAD_OVER_MAIL
  ARM_OVER_HAIR
  ARM_OVER_HAIR_BELOW_WEAPON
  HAND_BELOW_WEAPON
  HAND_OVER_HAIR
  HAND_OVER_WEAPON
  HEAD
} derive(Eq, Compare, Show)

///|
pub impl ToJson for BodyLayer with to_json(self) {
  self.to_string().to_json()
}

///|
pub fn int_value(self : BodyLayer) -> Int {
  match self {
    BodyLayer::BODY_NONE => 0
    BodyLayer::BODY => 1
    BodyLayer::ARM => 2
    BodyLayer::ARM_BELOW_HEAD => 3
    BodyLayer::ARM_BELOW_HEAD_OVER_MAIL => 4
    BodyLayer::ARM_OVER_HAIR => 5
    BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON => 6
    BodyLayer::HAND_BELOW_WEAPON => 7
    BodyLayer::HAND_OVER_HAIR => 8
    BodyLayer::HAND_OVER_WEAPON => 9
    BodyLayer::HEAD => 10
  }
}

///|
pub fn hash(self : BodyLayer) -> Int {
  self.int_value()
}

///|
pub impl Hash for BodyLayer with hash_combine(self, hasher) {
  hasher.combine(self.int_value())
}

///|
pub fn BodyLayer::layer_by_name(name : String) -> BodyLayer {
  let layer_iter = layers_by_name_[name]
  match layer_iter {
    None => {
      if name != "" {
        println("Unknown BodyLayer name: [" + name + "]")
      }
      BodyLayer::BODY_NONE
    }
    Some(v) => v
  }
}

///|
pub let layers_by_name_ : @immut/sorted_map.T[String, BodyLayer] = @immut/sorted_map.from_array([
    ("body", BodyLayer::BODY),
    ("backBody", BodyLayer::BODY),
    ("arm", BodyLayer::ARM),
    ("armBelowHead", BodyLayer::ARM_BELOW_HEAD),
    ("armBelowHeadOverMailChest", BodyLayer::ARM_BELOW_HEAD_OVER_MAIL),
    ("armOverHair", BodyLayer::ARM_OVER_HAIR),
    ("armOverHairBelowWeapon", BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON),
    ("handBelowWeapon", BodyLayer::HAND_BELOW_WEAPON),
    ("handOverHair", BodyLayer::HAND_OVER_HAIR),
    ("handOverWeapon", BodyLayer::HAND_OVER_WEAPON),
    ("head", BodyLayer::HEAD),
  ],
)
