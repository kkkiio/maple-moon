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
  let bodynode = @fs.read_file_to_string(
      "assets/Character/Body/00002000.img.json",
    )
    |> @json.parse
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )

  // Load head
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

  // Load hair
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

  look.set_stance(StanceId::STAND2)
  look.set_pos(Vec2(100.0, 100.0))

  // Add Crossbow (Item ID 1462000)
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/01462000.img.json",
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
  debug_inspect(@entity.iter_entities().to_array().length(), content=(#|10
  ))
  @capture_app.snapshot(
    "src/tests/char_look_test/__snapshot__/crossbow_stand1.png",
    capture.png,
  )
}
