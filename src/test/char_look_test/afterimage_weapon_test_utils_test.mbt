///|
fn weapon_name_for(item_id : Int) -> String {
  match item_id {
    1302000 => "Sword"
    1312001 => "Axe"
    1452000 => "Bow"
    1462000 => "Crossbow"
    _ => "Weapon"
  }
}

///|
fn weapon_file_id(item_id : Int) -> String {
  let mut text = item_id.to_string()
  while text.length() < 8 {
    text = "0" + text
  }
  text
}

///|
fn load_test_look(host : @entity.Entity) -> @char_look.CharLook raise {
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
  @char_look.CharLook::new(
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
}

///|
fn load_weapon_item(item_id : Int) -> @item.ItemData raise {
  let weapon_file = weapon_file_id(item_id)
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/\{weapon_file}.img.json",
    )
    |> @json.parse
  let weapon_info = match weapon_node {
    { "info": Object(info), .. } => info
    _ => Map::new()
  }
  let weapon_icons = (
    weapon_info.get("icon").map(json => @json.from_json(json)).unwrap(),
    weapon_info.get("iconRaw").map(json => @json.from_json(json)).unwrap(),
  )
  @item.ItemData::{
    src: weapon_node,
    icons: weapon_icons,
    item_id,
    price: 0,
    gender: 0,
    name: weapon_name_for(item_id),
    desc: "",
    category: "Weapon",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
}

///|
async fn snapshot_afterimage_case(
  item_id : Int,
  stance : @char_stance.StanceId,
  stance_key : String,
  after_image_name : String,
  facing_right : Bool,
  host_shift_x : Double,
  snapshot_path : String,
  visual_desc : String,
) -> Unit {
  let previous_world = @ecs.current_world()
  let world = @ecs.World::new()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  @capture_app.init_app(
    @app.App::new()
    .with_world(world)
    .with_viewport_width(220.0)
    .with_viewport_height(220.0)
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
    ),
  )

  let host = @entity.Entity::new()
  defer host.destroy()
  let after_image_host = host.spawn_child()
  defer @char_look.clear_after_image(after_image_host)
  defer @sprite.sprites().clear()
  @transform2d.set_xy(host, Vec2(110.0, 110.0))
  @transform2d.set_xy(after_image_host, Vec2(host_shift_x, 0.0))

  let look = load_test_look(host)
  let weapon_item = load_weapon_item(item_id)
  look.add_equip(weapon_item, @slot.Id::WEAPON)
  look.set_facing_right(facing_right)
  look.set_stance(stance)
  look.play_animations()

  let after_image_node = @fs.read_file_to_string(
      "assets/Character/Afterimage/\{after_image_name}.img.json",
    )
    |> @json.parse
  let after_images : @char_look.NxAfterImages = @json.from_json(
    after_image_node,
  )
  @char_look.set_after_images(after_image_name, after_images)

  let collection = @char_look.AfterImage::get_collection(after_image_name, 0)
  guard collection.get(stance_key) is Some(resource) else { panic() }

  @char_look.add_after_image(after_image_host, look, resource, facing_right)

  let mut ticks = 0
  while look.get_frame() < resource.first_frame && ticks < 60 {
    @time.set_delta(0.016)
    @capture_app.run_loop(0.016)
    ticks = ticks + 1
  }
  @time.set_delta(0.016)
  @capture_app.run_loop(0.016)

  @capture_app.snapshot(snapshot_path, visual_desc~)
}
