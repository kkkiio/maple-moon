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
    fn(character, first_frame, range, sprites) raise {
      debug_inspect(
        character,
        content=(
          #|{
          #|  stance: SHOOT2,
          #|  frame: 4,
          #|  weapon_id: 1462000,
          #|  top_id: 0,
          #|  bottom_id: 0,
          #|  shoes_id: 0,
          #|}
        ),
      )
      debug_inspect(
        (first_frame, range),
        content=(
          #|(4, { lt: { x: 0, y: 0 }, rb: { x: 0, y: 0 } })
        ),
      )
      debug_inspect(
        sprites,
        content=(
          #|[
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot2_body.png"),
          #|    source_rect: Some({ x: 124, y: 0, width: 31, height: 30 }),
          #|    destination_size: Some({ x: 31, y: 30 }),
          #|    anchor: { x: -0.27419354838709675, y: -0.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70005 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
          #|    destination_size: Some({ x: 26, y: 16 }),
          #|    anchor: { x: -0.2692307692307693, y: -2.4375 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70021 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
          #|    destination_size: Some({ x: 35, y: 20 }),
          #|    anchor: { x: -0.12857142857142856, y: -2.65 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70016 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
          #|    destination_size: Some({ x: 33, y: 17 }),
          #|    anchor: { x: -0.13636363636363635, y: -2.9705882352941178 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70020 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
          #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
          #|    destination_size: Some({ x: 38, y: 22 }),
          #|    anchor: { x: -0.10526315789473684, y: -2.4545454545454546 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70025 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot2_arm.png"),
          #|    source_rect: Some({ x: 92, y: 0, width: 23, height: 11 }),
          #|    destination_size: Some({ x: 23, y: 11 }),
          #|    anchor: { x: 0.28260869565217395, y: -2.227272727272727 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70044 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70044 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Body/00012000.img_shoot2_head.png"),
          #|    source_rect: Some({ x: 156, y: 0, width: 39, height: 35 }),
          #|    destination_size: Some({ x: 39, y: 35 }),
          #|    anchor: { x: -0.08974358974358976, y: -1.3 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70019 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Weapon/spritesheets/01462000.img.png"),
          #|    source_rect: Some({ x: 68, y: 17, width: 51, height: 17 }),
          #|    destination_size: Some({ x: 51, y: 17 }),
          #|    anchor: { x: -0.22549019607843135, y: -1.5 },
          #|    flip_x: true,
          #|    flip_y: false,
          #|    local_translation: Some({ x: 0, y: 0, z: 70036 }),
          #|    world_translation: Some({ x: 110, y: 110, z: 70036 }),
          #|  },
          #|  {
          #|    image_path: Some("assets/base/Character/Afterimage/crossBow.img/animation.png"),
          #|    source_rect: Some({ x: 398, y: 226, width: 99, height: 8 }),
          #|    destination_size: Some({ x: 99, y: 8 }),
          #|    anchor: { x: -0.2777777777777778, y: -3.25 },
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
