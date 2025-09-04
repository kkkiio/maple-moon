///|
pub(all) enum BodyLayer {
  BODY_NONE = 0
  BODY = 1
  ARM = 2
  ARM_BELOW_HEAD = 3
  ARM_BELOW_HEAD_OVER_MAIL = 4
  ARM_OVER_HAIR = 5
  ARM_OVER_HAIR_BELOW_WEAPON = 6
  HAND_BELOW_WEAPON = 7
  HAND_OVER_HAIR = 8
  HAND_OVER_WEAPON = 9
  HEAD = 10
} derive(Eq, Compare, Show, Hash)

///|
pub impl ToJson for BodyLayer with to_json(self) {
  self.to_string().to_json()
}

///|
pub fn int_value(self : BodyLayer) -> Int = "%identity"

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
