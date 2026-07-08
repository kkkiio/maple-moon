///|
test "weapon afterimage coverage: sword_1h" {
  snapshot_afterimage_case(
    1302000,
    @char_stance.StanceId::STABO1,
    "stabO1",
    "swordOL",
    true,
    10.0,
    "src/tests/char_look_test/__snapshot__/sword_1h_stabO1_afterimage.png",
  )
}
