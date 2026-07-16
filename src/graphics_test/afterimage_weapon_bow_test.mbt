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
    fn(character, first_frame, range, sprites) raise {
      debug_inspect(
        character,
        content=(
          #|{
          #|  stance: SHOOT1,
          #|  frame: 2,
          #|  weapon_id: 1452000,
          #|  top_id: 0,
          #|  bottom_id: 0,
          #|  shoes_id: 0,
          #|}
        ),
      )
      debug_inspect(
        (first_frame, range),
        content=(
          #|(2, { lt: { x: 0, y: 0 }, rb: { x: 0, y: 0 } })
        ),
      )
      debug_inspect(
        sprites,
        content=(
          #|[
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot1_body.png"),
          #|    source_rect: Some({ x: 74, y: 0, width: 37, height: 31 }),
          #|    destination_size: Some({ x: 37, y: 31 }),
          #|    anchor: { x: -0.33783783783783783, y: -0.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70005 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
          #|    destination_size: Some({ x: 26, y: 16 }),
          #|    anchor: { x: -0.2692307692307693, y: -2.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70021 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
          #|    destination_size: Some({ x: 35, y: 20 }),
          #|    anchor: { x: -0.12857142857142856, y: -2.7 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70016 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
          #|    destination_size: Some({ x: 33, y: 17 }),
          #|    anchor: { x: -0.13636363636363635, y: -3.0294117647058822 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70020 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
          #|    destination_size: Some({ x: 38, y: 22 }),
          #|    anchor: { x: -0.10526315789473684, y: -2.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70025 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot1_arm.png"),
          #|    source_rect: Some({ x: 46, y: 0, width: 23, height: 11 }),
          #|    destination_size: Some({ x: 23, y: 11 }),
          #|    anchor: { x: 0.3695652173913043, y: -2.6818181818181817 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70044 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70044 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00012000.img_shoot1_head.png"),
          #|    source_rect: Some({ x: 78, y: 0, width: 39, height: 35 }),
          #|    destination_size: Some({ x: 39, y: 35 }),
          #|    anchor: { x: -0.08974358974358976, y: -1.3285714285714285 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70019 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Weapon/spritesheets/01452000.img.png"),
          #|    source_rect: Some({ x: 194, y: 0, width: 25, height: 59 }),
          #|    destination_size: Some({ x: 25, y: 59 }),
          #|    anchor: { x: -0.94, y: -0.4491525423728814 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70033 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70033 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Afterimage/bow.img/animation.png"),
          #|    source_rect: Some({ x: 99, y: 354, width: 99, height: 8 }),
          #|    destination_size: Some({ x: 99, y: 8 }),
          #|    anchor: { x: -0.5404040404040404, y: -3.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 0 }),
          #|    world_translation: Some({ x: 118, y: 110, z: 0 }),
          #|  },
          #|]
        ),
      )
    },
  )
}
