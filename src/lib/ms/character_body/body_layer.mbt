///|
pub(all) enum BodyLayer {
  // BODY_NONE = 0
  // BODY = 1
  // ARM = 2
  // ARM_BELOW_HEAD = 3
  // ARM_BELOW_HEAD_OVER_MAIL = 4
  // ARM_OVER_HAIR = 5
  // ARM_OVER_HAIR_BELOW_WEAPON = 6
  // HAND_BELOW_WEAPON = 7
  // HAND_OVER_HAIR = 8
  // HAND_OVER_WEAPON = 9
  // HEAD = 10
  BODY = 5
  ARM = 35
  ARM_BELOW_HEAD = 9
  ARM_BELOW_HEAD_OVER_MAIL = 15
  ARM_OVER_HAIR = 44
  ARM_OVER_HAIR_BELOW_WEAPON = 45
  HAND_BELOW_WEAPON = 43
  HAND_OVER_HAIR = 48
  HAND_OVER_WEAPON = 49
  HEAD = 19
} derive(Eq, Compare, Show, Hash)

///|
pub impl ToJson for BodyLayer with to_json(self) {
  self.to_string().to_json()
}

///|
pub fn BodyLayer::int_value(self : BodyLayer) -> Int = "%identity"

///|
pub fn BodyLayer::from_name(name : String) -> BodyLayer? {
  let it = match name {
    "body" => BodyLayer::BODY
    "backBody" => BodyLayer::BODY
    "arm" => BodyLayer::ARM
    "armBelowHead" => BodyLayer::ARM_BELOW_HEAD
    "armBelowHeadOverMailChest" => BodyLayer::ARM_BELOW_HEAD_OVER_MAIL
    "armOverHair" => BodyLayer::ARM_OVER_HAIR
    "armOverHairBelowWeapon" => BodyLayer::ARM_OVER_HAIR_BELOW_WEAPON
    "handBelowWeapon" => BodyLayer::HAND_BELOW_WEAPON
    "handOverHair" => BodyLayer::HAND_OVER_HAIR
    "handOverWeapon" => BodyLayer::HAND_OVER_WEAPON
    "head" => BodyLayer::HEAD
    "backHead" => BodyLayer::HEAD
    _ => return None
  }
  Some(it)
}
