///|
async test "weapon afterimage coverage: axe_1h" {
  snapshot_afterimage_case(
    1312001,
    @char_stance.StanceId::STABO1,
    "stabO1",
    "swordOL",
    true,
    10.0,
    "src/tests/char_look_test/__snapshot__/axe_1h_stabO1_afterimage.png",
    "A character faces right and performs a one-handed melee thrust, with a translucent slash effect aligned near the weapon tip.",
  )
}
