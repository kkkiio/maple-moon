///|
test "weapon afterimage coverage: bow" {
  snapshot_afterimage_case(
    1452000,
    @char_stance.StanceId::SHOOT1,
    "shoot1",
    "bow",
    true,
    8.0,
    "src/graphics_test/__snapshot__/char_look/bow_shoot1_afterimage.png",
  )
}
