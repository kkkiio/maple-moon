// No using here to avoid duplicate declaration in the same package

///|
test "character with crossbow equipment" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  // Load body
  let bodynode = @res.load_json("res://Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )

  // Load head
  let headnode = @res.load_json("res://Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )

  let draw_info = @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)

  // Load hair
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @res.load_json(
      "res://Character/Hair/00030000.img.json",
    )
    |> @json.from_json

  let entity = @entity.Entity()
  let look = @cp.CharLook(
    entity,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @cp.Face(20000, @res.load_json("res://Character/Face/00020000.img.json")),
    draw_info,
  )

  look.set_stance(StanceId::STAND2)
  look.set_pos(Vec2(100.0, 100.0))

  // Add Crossbow (Item ID 1462000)
  let weapon_node = @res.load_json("res://Character/Weapon/01462000.img.json")
  let weapon_info = match weapon_node {
    { "info": Object(info), .. } => info
    _ => Map([])
  }
  let weapon_icons = (
    weapon_info.get("icon").map(json => @json.from_json(json)).unwrap(),
    weapon_info.get("iconRaw").map(json => @json.from_json(json)).unwrap(),
  )
  let weapon_item = @item.ItemData::{
    src: weapon_node,
    icons: weapon_icons,
    item_id: 1462000,
    price: 0,
    gender: 0,
    name: "Crossbow",
    desc: "",
    category: "Weapon",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  look.add_equip(weapon_item, @slot.Id::WEAPON)
  look.set_stance(StanceId::STAND2)
  look.play_animations()

  // Capture
  let capture = @capture_app.capture_after_frames(
    @app.App()
    .with_world(world)
    .with_viewport_width(200.0)
    .with_viewport_height(200.0)
    .add_plugin(@plugins.default_plugin),
    1,
    width=200,
    height=200,
    raw_delta=0.016,
  )
  debug_inspect(
    character_render_state(look),
    content=(
      #|{
      #|  stance: STAND2,
      #|  frame: 0,
      #|  weapon_id: 1462000,
      #|  top_id: 0,
      #|  bottom_id: 0,
      #|  shoes_id: 0,
      #|}
    ),
  )
  debug_inspect(
    render_sprite_state(capture),
    content=(
      #|[
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_stand2_body.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 20, height: 31 }),
      #|    destination_size: Some({ x: 20, y: 31 }),
      #|    anchor: { x: 0.25, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70005 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
      #|    destination_size: Some({ x: 35, y: 20 }),
      #|    anchor: { x: 0.12857142857142856, y: -2.7 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70016 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
      #|    destination_size: Some({ x: 33, y: 17 }),
      #|    anchor: { x: 0.13636363636363635, y: -3.0294117647058822 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70020 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
      #|    destination_size: Some({ x: 38, y: 22 }),
      #|    anchor: { x: 0.10526315789473684, y: -2.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70025 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_stand2_arm.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 10, height: 13 }),
      #|    destination_size: Some({ x: 10, y: 13 }),
      #|    anchor: { x: -0.09999999999999998, y: -1.7307692307692308 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70035 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70035 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_stand2_hand.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 19, height: 24 }),
      #|    destination_size: Some({ x: 19, y: 24 }),
      #|    anchor: { x: 0.4473684210526315, y: -0.5833333333333333 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70048 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70048 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00012000.img_stand2_head.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 39, height: 35 }),
      #|    destination_size: Some({ x: 39, y: 35 }),
      #|    anchor: { x: 0.08974358974358976, y: -1.3285714285714285 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70019 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
      #|    destination_size: Some({ x: 26, y: 16 }),
      #|    anchor: { x: 0.2692307692307693, y: -2.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70021 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Weapon/spritesheets/01462000.img.png"),
      #|    source_rect: Some({ x: 39, y: 114, width: 39, height: 39 }),
      #|    destination_size: Some({ x: 39, y: 39 }),
      #|    anchor: { x: 0.08974358974358976, y: -0.6025641025641026 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70037 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70037 }),
      #|  },
      #|]
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/crossbow_stand1.png",
    capture.png,
  )
}
