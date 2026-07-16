///|
using @char_stance {type StanceId}

///|
test "character climbing ladder" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let bodynode = @res.load_json("res://Character/Body/00002000.img.json")
  let stance_bodys_map : NxStanceLooks[NxStanceBody] = @json.from_json(bodynode)
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

  // Set Climbing Stance
  look.set_stance(StanceId::LADDER)
  look.set_pos(Vec2(100.0, 100.0))

  // Add Weapon
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

  // Add Coat
  let coat_node = @res.load_json("res://Character/Coat/01040002.img.json")
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
  let pants_node = @res.load_json("res://Character/Pants/01060002.img.json")
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
  let shoes_node = @res.load_json("res://Character/Shoes/01072001.img.json")
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
      #|  stance: LADDER,
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
      #|    image_path: Some("assets/base/Character/Body/00002000.img_ladder_body.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 24, height: 45 }),
      #|    destination_size: Some({ x: 24, y: 45 }),
      #|    anchor: { x: -0.041666666666666685, y: -0.4555555555555556 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70005 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 106, y: 0, width: 38, height: 33 }),
      #|    destination_size: Some({ x: 38, y: 33 }),
      #|    anchor: { x: 0, y: -1.4090909090909092 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70024 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70024 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 144, y: 0, width: 35, height: 32 }),
      #|    destination_size: Some({ x: 35, y: 32 }),
      #|    anchor: { x: 0.014285714285714235, y: -1.4375 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70006 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70006 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00012000.img_ladder_head.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 41, height: 35 }),
      #|    destination_size: Some({ x: 41, y: 35 }),
      #|    anchor: { x: 0.012195121951219523, y: -1.2714285714285714 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70019 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Coat/01040002.img.png"),
      #|    source_rect: Some({ x: 200, y: 0, width: 18, height: 13 }),
      #|    destination_size: Some({ x: 18, y: 13 }),
      #|    anchor: { x: 0.05555555555555558, y: -1.8076923076923075 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70014 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70014 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Pants/01060002.img.png"),
      #|    source_rect: Some({ x: 187, y: 0, width: 16, height: 12 }),
      #|    destination_size: Some({ x: 16, y: 12 }),
      #|    anchor: { x: 0, y: -1.1666666666666667 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70012 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70012 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Shoes/01072001.img.png"),
      #|    source_rect: Some({ x: 231, y: 0, width: 16, height: 12 }),
      #|    destination_size: Some({ x: 16, y: 12 }),
      #|    anchor: { x: 0, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70008 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70008 }),
      #|  },
      #|]
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/climb.png",
    capture.png,
  )
}
