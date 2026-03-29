///|
test "char_look/types facade forwards body layer" {
  inspect(BodyLayer::from_name("handMove"), content="None")
  inspect(BodyLayer::from_name("handBelowWeapon") is Some(_), content="true")
}
