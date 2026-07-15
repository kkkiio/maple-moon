///|
using @char_look {type NxStanceLooks}

///|
using @types {type NxStanceBody}

///|
test "character stand1" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let bodynode = @fs.read_file_to_string(
      "assets/Character/Body/00002000.img.json",
    )
    |> @json.parse
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = @fs.read_file_to_string(
      "assets/Character/Body/00012000.img.json",
    )
    |> @json.parse
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @fs.read_file_to_string(
      "assets/Character/Hair/00030000.img.json",
    )
    |> @json.parse
    |> @json.from_json
  let entity = @entity.Entity()
  let look = @cp.CharLook(
    entity,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @cp.Face(
      20000,
      @fs.read_file_to_string("assets/Character/Face/00020000.img.json")
      |> @json.parse,
    ),
    draw_info,
  )
  look.set_stance(StanceId::STAND1)
  look.set_pos(Vec2(100.0, 100.0))
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/01302000.img.json",
    )
    |> @json.parse
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

  // Add Coat
  let coat_node = @fs.read_file_to_string(
      "assets/Character/Coat/01040002.img.json",
    )
    |> @json.parse
  let coat_info = match coat_node {
    { "info": Object(info), .. } => info
    _ => Map([])
  }
  let coat_icons = (
    coat_info.get("icon").map(json => @json.from_json(json)).unwrap(),
    coat_info.get("iconRaw").map(json => @json.from_json(json)).unwrap(),
  )
  let coat_item = @item.ItemData::{
    src: coat_node,
    icons: coat_icons,
    item_id: 1040002,
    price: 0,
    gender: 0,
    name: "Coat",
    desc: "",
    category: "Coat",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  look.add_equip(coat_item, @slot.Id::TOP)

  // Add Pants
  let pants_node = @fs.read_file_to_string(
      "assets/Character/Pants/01060002.img.json",
    )
    |> @json.parse
  let pants_info = match pants_node {
    { "info": Object(info), .. } => info
    _ => Map([])
  }
  let pants_icons = (
    pants_info.get("icon").map(json => @json.from_json(json)).unwrap(),
    pants_info.get("iconRaw").map(json => @json.from_json(json)).unwrap(),
  )
  let pants_item = @item.ItemData::{
    src: pants_node,
    icons: pants_icons,
    item_id: 1060002,
    price: 0,
    gender: 0,
    name: "Pants",
    desc: "",
    category: "Pants",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  look.add_equip(pants_item, @slot.Id::BOTTOM)

  // Add Shoes
  let shoes_node = @fs.read_file_to_string(
      "assets/Character/Shoes/01072001.img.json",
    )
    |> @json.parse
  let shoes_info = match shoes_node {
    { "info": Object(info), .. } => info
    _ => Map([])
  }
  let shoes_icons = (
    shoes_info.get("icon").map(json => @json.from_json(json)).unwrap(),
    shoes_info.get("iconRaw").map(json => @json.from_json(json)).unwrap(),
  )
  let shoes_item = @item.ItemData::{
    src: shoes_node,
    icons: shoes_icons,
    item_id: 1072001,
    price: 0,
    gender: 0,
    name: "Red Rubber Boots",
    desc: "",
    category: "Shoes",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  look.add_equip(shoes_item, @slot.Id::SHOES)
  look.play_animations()
  // Initialize test app and run one loop
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
      #|  stance: STAND1,
      #|  frame: 0,
      #|  weapon_id: 1302000,
      #|  top_id: 1040002,
      #|  bottom_id: 1060002,
      #|  shoes_id: 1072001,
      #|}
    ),
  )
  debug_inspect(
    render_sprite_state(capture),
    content=(
      #|[
      #|  {
      #|    image_path: Some("assets/Character/Body/00002000.img_stand1_body.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 23, height: 31 }),
      #|    destination_size: Some({ x: 23, y: 31 }),
      #|    anchor: { x: 0.28260869565217395, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70005 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
      #|    destination_size: Some({ x: 35, y: 20 }),
      #|    anchor: { x: 0.12857142857142856, y: -2.7 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70016 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
      #|    destination_size: Some({ x: 33, y: 17 }),
      #|    anchor: { x: 0.13636363636363635, y: -3.0294117647058822 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70020 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
      #|    destination_size: Some({ x: 38, y: 22 }),
      #|    anchor: { x: 0.10526315789473684, y: -2.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70025 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Body/00002000.img_stand1_arm.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 11, height: 19 }),
      #|    destination_size: Some({ x: 11, y: 19 }),
      #|    anchor: { x: -0.40909090909090906, y: -1.0263157894736843 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70035 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70035 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Body/00012000.img_stand1_head.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 39, height: 35 }),
      #|    destination_size: Some({ x: 39, y: 35 }),
      #|    anchor: { x: 0.08974358974358976, y: -1.3285714285714285 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70019 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Face/00020000.img_default_face.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
      #|    destination_size: Some({ x: 26, y: 16 }),
      #|    anchor: { x: 0.2692307692307693, y: -2.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70021 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Weapon/01302000.img_stand1.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 41, height: 13 }),
      #|    destination_size: Some({ x: 41, y: 13 }),
      #|    anchor: { x: 0.1585365853658537, y: -0.8076923076923077 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70036 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70036 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Coat/01040002.img.png"),
      #|    source_rect: Some({ x: 910, y: 0, width: 14, height: 14 }),
      #|    destination_size: Some({ x: 14, y: 14 }),
      #|    anchor: { x: 0.2857142857142857, y: -1.7142857142857144 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70014 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70014 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Coat/01040002.img.png"),
      #|    source_rect: Some({ x: 924, y: 0, width: 5, height: 7 }),
      #|    destination_size: Some({ x: 5, y: 7 }),
      #|    anchor: { x: -0.7, y: -3.6428571428571432 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70034 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70034 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Pants/01060002.img.png"),
      #|    source_rect: Some({ x: 697, y: 0, width: 16, height: 11 }),
      #|    destination_size: Some({ x: 16, y: 11 }),
      #|    anchor: { x: 0.25, y: -1.4090909090909092 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70012 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70012 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/Character/Shoes/01072001.img.png"),
      #|    source_rect: Some({ x: 930, y: 0, width: 20, height: 9 }),
      #|    destination_size: Some({ x: 20, y: 9 }),
      #|    anchor: { x: 0.25, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70008 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70008 }),
      #|  },
      #|]
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/stand1.png",
    capture.png,
  )
}
