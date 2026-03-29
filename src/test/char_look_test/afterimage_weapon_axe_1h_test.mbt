///|
async test "weapon afterimage coverage: axe_1h" {
  snapshot_afterimage_case(
    1312001,
    @char_stance.StanceId::STABO1,
    "stabO1",
    "swordOL",
    true,
    10.0,
    "src/test/char_look_test/__snapshot__/axe_1h_stabO1_afterimage.png",
    "A character faces right and attacks with a one-handed melee weapon, with a translucent slash effect following the weapon arc.",
  )
}
