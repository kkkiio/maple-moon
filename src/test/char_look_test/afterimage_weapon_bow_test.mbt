///|
async test "weapon afterimage coverage: bow" {
  snapshot_afterimage_case(
    1452000,
    @char_stance.StanceId::SHOOT1,
    "shoot1",
    "bow",
    true,
    8.0,
    "src/test/char_look_test/__snapshot__/bow_shoot1_afterimage.png",
    "A character faces right and shoots a bow, with a translucent projectile-trail effect in front of the bow.",
  )
}
