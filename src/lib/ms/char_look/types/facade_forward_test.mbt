///|
test "char_look/types facade forwards body layer" {
  debug_inspect(
    BodyLayer::from_name("handMove"),
    content=(
      #|None
    ),
  )
  debug_inspect(
    BodyLayer::from_name("handBelowWeapon"),
    content=(
      #|Some(HAND_BELOW_WEAPON)
    ),
  )
}
