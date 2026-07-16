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
  @capture_app.ensure_native_context(width=200, height=200)

  let host = @entity.Entity()
  defer host.destroy()
  let after_image_host = host.spawn_child()
  defer @char_look.clear_after_image(after_image_host)
  defer @sprite.sprites().clear()
  @transform2d.set_xy(host, Vec2(100.0, 100.0))
  // Keep the effect closer to the muzzle side for left-facing shoot pose.
  @transform2d.set_xy(after_image_host, Vec2(-16.0, 0.0))

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
  let look = @cp.CharLook(
    host,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @cp.Face(20000, @res.load_json("res://Character/Face/00020000.img.json")),
    draw_info,
  )
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
    character_render_state(look),
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
    (shoot2_resource.first_frame, shoot2_resource.range),
    content=(
      #|(4, { lt: { x: 0, y: 0 }, rb: { x: 0, y: 0 } })
    ),
  )
  debug_inspect(
    render_sprite_state(capture),
    content=(
      #|[
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot2_body.png"),
      #|    source_rect: Some({ x: 124, y: 0, width: 31, height: 30 }),
      #|    destination_size: Some({ x: 31, y: 30 }),
      #|    anchor: { x: 0.27419354838709675, y: -0.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70005 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70005 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Face/00020000.img_default_face.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 26, height: 16 }),
      #|    destination_size: Some({ x: 26, y: 16 }),
      #|    anchor: { x: 0.2692307692307693, y: -2.4375 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70021 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70021 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 0, y: 0, width: 35, height: 20 }),
      #|    destination_size: Some({ x: 35, y: 20 }),
      #|    anchor: { x: 0.12857142857142856, y: -2.65 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70016 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70016 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 73, y: 0, width: 33, height: 17 }),
      #|    destination_size: Some({ x: 33, y: 17 }),
      #|    anchor: { x: 0.13636363636363635, y: -2.9705882352941178 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70020 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70020 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Hair/00030000.img.png"),
      #|    source_rect: Some({ x: 35, y: 0, width: 38, height: 22 }),
      #|    destination_size: Some({ x: 38, y: 22 }),
      #|    anchor: { x: 0.10526315789473684, y: -2.4545454545454546 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70025 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70025 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00002000.img_shoot2_arm.png"),
      #|    source_rect: Some({ x: 92, y: 0, width: 23, height: 11 }),
      #|    destination_size: Some({ x: 23, y: 11 }),
      #|    anchor: { x: -0.28260869565217395, y: -2.227272727272727 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70044 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70044 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Body/00012000.img_shoot2_head.png"),
      #|    source_rect: Some({ x: 156, y: 0, width: 39, height: 35 }),
      #|    destination_size: Some({ x: 39, y: 35 }),
      #|    anchor: { x: 0.08974358974358976, y: -1.3 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70019 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70019 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Weapon/spritesheets/01462000.img.png"),
      #|    source_rect: Some({ x: 68, y: 17, width: 51, height: 17 }),
      #|    destination_size: Some({ x: 51, y: 17 }),
      #|    anchor: { x: 0.22549019607843135, y: -1.5 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 70036 }),
      #|    world_translation: Some({ x: 100, y: 100, z: 70036 }),
      #|  },
      #|  {
      #|    image_path: Some("assets/base/Character/Afterimage/crossBow.img/animation.png"),
      #|    source_rect: Some({ x: 398, y: 226, width: 99, height: 8 }),
      #|    destination_size: Some({ x: 99, y: 8 }),
      #|    anchor: { x: 0.2777777777777778, y: -3.25 },
      #|    flip_x: false,
      #|    flip_y: false,
      #|    local_translation: Some({ x: 0, y: 0, z: 0 }),
      #|    world_translation: Some({ x: 84, y: 100, z: 0 }),
      #|  },
      #|]
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/char_look/crossbow_shoot2_afterimage_left.png",
    capture.png,
  )
}
