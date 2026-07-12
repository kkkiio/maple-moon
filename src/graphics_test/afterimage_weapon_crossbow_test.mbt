///|
test "weapon afterimage coverage: crossbow" {
  snapshot_afterimage_case(
    1462000,
    @char_stance.StanceId::SHOOT2,
    "shoot2",
    "crossBow",
    true,
    10.0,
    "src/graphics_test/__snapshot__/char_look/crossbow_shoot2_afterimage.png",
  )
}
