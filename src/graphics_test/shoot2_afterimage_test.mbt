///|
test "crossbow shoot2 afterimage without range should render" {
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
    .add_system(
      Update,
      fn(world) { @cp.char_look_system(world) },
      system_name="char_look_system",
    )
    .add_system(
      Update,
      fn(world) { @char_look.update_after_image_system(world) },
      system_name="after_image_system",
    )

  let host = @entity.Entity()
  defer host.destroy()
  let after_image_host = host.spawn_child()
  defer @char_look.clear_after_image(after_image_host)
  defer @sprite.sprites().clear()
  @transform2d.set_xy(host, Vec2(100.0, 100.0))
  // Keep the effect closer to the muzzle side for left-facing shoot pose.
  @transform2d.set_xy(after_image_host, Vec2(-16.0, 0.0))

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
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @fs.read_file_to_string(
      "assets/Character/Hair/00030000.img.json",
    )
    |> @json.parse
    |> @json.from_json
  let look = @char_look.CharLook::new(
    host,
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
  look.set_stance(StanceId::SHOOT2)
  look.play_animations()

  let after_images = @char_look.load_after_images("crossBow")
  @char_look.set_after_images("crossBow", after_images)

  let collection = @char_look.AfterImage::get_collection("crossBow", 0)
  guard collection.get("shoot2") is Some(shoot2_resource) else {
    abort("shoot2 resource not found in test")
  }

  @char_look.add_after_image(after_image_host, look, shoot2_resource, false)
  // Drive character animation to the frame where shoot2 afterimage should appear.
  let mut ticks = 0
  while look.get_frame() < shoot2_resource.first_frame && ticks < 60 {
    app.run_frames(1, raw_delta=0.016)
    ticks = ticks + 1
  }
  assert_true(look.get_frame() >= shoot2_resource.first_frame)
  let sprites = @sprite.sprites().iter().collect()
  assert_true(sprites.length() > 0)

  let capture = @capture_app.capture_after_frames(
    app,
    1,
    width=200,
    height=200,
    raw_delta=0.016,
  )
  debug_inspect(
    @entity.iter_entities().to_array().length(),
    content=(
      #|11
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/crossbow_shoot2_afterimage_left.png",
    capture.png,
  )
}
