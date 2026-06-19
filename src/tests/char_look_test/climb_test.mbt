///|
using @char_stance {type StanceId}

///|
async test "character climbing ladder" {
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
  let stance_bodys_map : NxStanceLooks[NxStanceBody] = @json.from_json(bodynode)
  let headnode = @fs.read_file_to_string(
      "assets/Character/Body/00012000.img.json",
    )
    |> @json.parse
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @fs.read_file_to_string(
      "assets/Character/Hair/00030000.img.json",
    )
    |> @json.parse
    |> @json.from_json
  let entity = @entity.Entity()
  let look = @char_look.CharLook::new(
    entity,
    {},
    @char_look.FullBody::new(
      0,
      draw_info,
      stance_bodys_map.0,
      stance_heads_map.0,
    ),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @char_look.Face::new(
      20000,
      @fs.read_file_to_string("assets/Character/Face/00020000.img.json")
      |> @json.parse,
    ),
    draw_info,
  )

  // Set Climbing Stance
  look.set_stance(StanceId::LADDER)
  look.set_pos(Vec2(100.0, 100.0))

  // Add Weapon
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
  @capture_app.snapshot(
    "src/tests/char_look_test/__snapshot__/climb.png",
    capture.png,
    visual_desc="2D game snapshot with visible character-related rendering.",
  )
}
