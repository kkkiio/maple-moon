///|
test "weapon afterimage coverage: crossbow" {
  snapshot_afterimage_case(
    1462000,
    @char_stance.StanceId::SHOOT2,
    "shoot2",
    "crossBow",
    true,
    10.0,
    "src/test/char_look_test/__snapshot__/crossbow_shoot2_afterimage.png",
    "A character faces right and fires a crossbow, with a translucent attack effect rendered just ahead of the weapon.",
  )
}
