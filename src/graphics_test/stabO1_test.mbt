///|
test "character stabO1" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let app = @app.App()
    .with_world(world)
    .with_viewport_width(200.0)
    .with_viewport_height(200.0)
    .add_plugin(@plugins.default_plugin)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let bodynode = @res.load_json("res://Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = @res.load_json("res://Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)
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
  look.set_stance(StanceId::STABO1)
  look.set_pos(Vec2(100.0, 100.0))
  let weapon_node = @res.load_json("res://Character/Weapon/01302000.img.json")
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
    item_id: 1302000,
    price: 0,
    gender: 0,
    name: "Sword",
    desc: "",
    category: "Weapon",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  look.add_equip(weapon_item, @slot.Id::WEAPON)
  look.play_animations()

  let capture = @capture_app.capture_after_frames(
    app,
    2,
    width=200,
    height=200,
    raw_delta=0.016,
  )
  debug_inspect(
    character_render_state(look),
    content=(
      #|{
      #|  stance: STABO1,
      #|  frame: 0,
      #|  weapon_id: 1302000,
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
      #|    image_path: Some("assets/base/Character/Body/00002000.img_stabO1_body.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 39, height: 29 }),
      #|    destination_size: Some({ x: 39, y: 29 }),
      #|    anchor: { x: 0.2692307692307693, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70005 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
      #|    destination_size: Some({ x: 35, y: 20 }),
      #|    anchor: { x: 0.12857142857142856, y: -2.55 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70016 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
      #|    destination_size: Some({ x: 33, y: 17 }),
      #|    anchor: { x: 0.13636363636363635, y: -2.8529411764705883 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70020 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
      #|    destination_size: Some({ x: 38, y: 22 }),
      #|    anchor: { x: 0.10526315789473684, y: -2.3636363636363638 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70025 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_stabO1_arm.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 18 }),
      #|    destination_size: Some({ x: 26, y: 18 }),
      #|    anchor: { x: -0.5, y: -1.0555555555555556 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70035 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70035 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00012000.img_stabO1_head.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 39, height: 35 }),
      #|    destination_size: Some({ x: 39, y: 35 }),
      #|    anchor: { x: 0.08974358974358976, y: -1.2428571428571429 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70019 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
      #|    destination_size: Some({ x: 26, y: 16 }),
      #|    anchor: { x: 0.2692307692307693, y: -2.3125 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70021 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Weapon/01302000.img_stabO1.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 43, height: 8 }),
      #|    destination_size: Some({ x: 43, y: 8 }),
      #|    anchor: { x: 0.05813953488372092, y: -1.75 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70036 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70036 }),
      #|  },
      #|]
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/stabO1_0.png",
    capture.png,
  )
}
