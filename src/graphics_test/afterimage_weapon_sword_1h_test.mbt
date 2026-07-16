///|
test "weapon afterimage coverage: sword_1h" {
  snapshot_afterimage_case(
    1302000,
    @char_stance.StanceId::STABO1,
    "stabO1",
    "swordOL",
    true,
    10.0,
    "src/graphics_test/__snapshot__/char_look/sword_1h_stabO1_afterimage.png",
    fn(character, first_frame, range, sprites) raise {
      debug_inspect(
        character,
        content=(
          #|{
          #|  stance: STABO1,
          #|  frame: 1,
          #|  weapon_id: 1302000,
          #|  top_id: 0,
          #|  bottom_id: 0,
          #|  shoes_id: 0,
          #|}
        ),
      )
      debug_inspect(
        (first_frame, range),
        content=(
          #|(1, { lt: { x: -84, y: -30 }, rb: { x: -20, y: -15 } })
        ),
      )
      debug_inspect(
        sprites,
        content=(
          #|[
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_stabO1_body.png"),
          #|    source_rect: Some({ x: 39, y: 0, width: 39, height: 29 }),
          #|    destination_size: Some({ x: 39, y: 29 }),
          #|    anchor: { x: -0.2692307692307693, y: -0.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70005 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
          #|    destination_size: Some({ x: 26, y: 16 }),
          #|    anchor: { x: -1, y: -2.125 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70021 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
          #|    destination_size: Some({ x: 35, y: 20 }),
          #|    anchor: { x: -0.6714285714285715, y: -2.4 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70016 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
          #|    destination_size: Some({ x: 33, y: 17 }),
          #|    anchor: { x: -0.7121212121212122, y: -2.676470588235294 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70020 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
          #|    destination_size: Some({ x: 38, y: 22 }),
          #|    anchor: { x: -0.605263157894737, y: -2.227272727272727 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70025 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_stabO1_arm.png"),
          #|    source_rect: Some({ x: 26, y: 0, width: 26, height: 18 }),
          #|    destination_size: Some({ x: 26, y: 18 }),
          #|    anchor: { x: -1.1923076923076923, y: -1 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70044 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70044 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00012000.img_stabO1_head.png"),
          #|    source_rect: Some({ x: 39, y: 0, width: 39, height: 35 }),
          #|    destination_size: Some({ x: 39, y: 35 }),
          #|    anchor: { x: -0.5769230769230769, y: -1.1571428571428573 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70019 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Weapon/01302000.img_stabO1.png"),
          #|    source_rect: Some({ x: 43, y: 0, width: 43, height: 8 }),
          #|    destination_size: Some({ x: 43, y: 8 }),
          #|    anchor: { x: -1.1744186046511629, y: -2.75 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70036 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70036 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Afterimage/swordOL.img/animation.png"),
          #|    source_rect: Some({ x: 808, y: 224, width: 49, height: 28 }),
          #|    destination_size: Some({ x: 49, y: 28 }),
          #|    anchor: { x: -1.2142857142857142, y: -0.8214285714285714 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 0 }),
          #|    world_translation: Some({ x: 120, y: 110, z: 0 }),
          #|  },
          #|]
        ),
      )
    },
  )
}
