///|
test "weapon afterimage coverage: axe_1h" {
  snapshot_afterimage_case(
    1312001,
    @char_stance.StanceId::STABO1,
    "stabO1",
    "swordOL",
    true,
    10.0,
    "src/graphics_test/__snapshot__/char_look/axe_1h_stabO1_afterimage.png",
  )
}
