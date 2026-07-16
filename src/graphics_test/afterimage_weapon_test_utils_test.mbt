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
struct CharacterRenderState {
  stance : @char_stance.StanceId
  frame : Int
  weapon_id : Int
  top_id : Int
  bottom_id : Int
  shoes_id : Int
} derive(Debug)

///|
fn character_render_state(look : @char_look.CharLook) -> CharacterRenderState {
  let equips = look.get_equips()
  {
    stance: look.get_stance(),
    frame: look.get_frame(),
    weapon_id: equips.get_equip(@slot.Id::WEAPON),
    top_id: equips.get_equip(@slot.Id::TOP),
    bottom_id: equips.get_equip(@slot.Id::BOTTOM),
    shoes_id: equips.get_equip(@slot.Id::SHOES),
  }
}

///|
struct RenderSpriteState {
  image_path : String?
  source_rect : @runtime_debug.DebugRect?
  destination_size : @runtime_debug.DebugVec2?
  anchor : @runtime_debug.DebugVec2
  flip_x : Bool
  flip_y : Bool
  local_translation : @runtime_debug.DebugVec3?
  world_translation : @runtime_debug.DebugVec3?
} derive(Debug)

///|
fn render_sprite_state(
  capture : @runtime_debug.FrameCaptureArtifact,
  entity_ids? : Array[UInt] = [],
) -> Array[RenderSpriteState] {
  let states : Array[RenderSpriteState] = []
  for item in capture.metadata.sprites {
    if !entity_ids.is_empty() && !entity_ids.contains(item.entity_id) {
      continue
    }
    states.push({
      image_path: item.image_path,
      source_rect: item.source_rect,
      destination_size: item.destination_size,
      anchor: item.anchor,
      flip_x: item.flip_x,
      flip_y: item.flip_y,
      local_translation: item.local_translation,
      world_translation: item.world_translation,
    })
  }
  states
}

///|
struct RenderDrawState {
  layer : String
  kind : String
  texture_path : String?
  source_rect : @runtime_debug.DebugRect?
  destination_rect : @runtime_debug.DebugRect?
  color : @runtime_debug.DebugColor?
} derive(Debug)

///|
fn render_draw_state(
  capture : @runtime_debug.FrameCaptureArtifact,
  entity_ids? : Array[UInt] = [],
) -> Array[RenderDrawState] {
  let states : Array[RenderDrawState] = []
  for item in capture.metadata.draw2d {
    if !entity_ids.is_empty() &&
      !item.entity_id.map_or(false, fn(id) { entity_ids.contains(id) }) {
      continue
    }
    states.push({
      layer: item.layer,
      kind: item.kind,
      texture_path: item.texture_path,
      source_rect: item.source_rect,
      destination_rect: item.destination_rect,
      color: item.color,
    })
  }
  states
}

///|
fn load_test_look(host : @entity.Entity) -> @char_look.CharLook raise {
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
  @cp.CharLook(
    host,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @cp.Face(20000, @res.load_json("res://Character/Face/00020000.img.json")),
    draw_info,
  )
}

///|
fn load_weapon_item(item_id : Int) -> @item.ItemData raise {
  let weapon_file = weapon_file_id(item_id)
  let weapon_node = @res.load_json(
    "res://Character/Weapon/\{weapon_file}.img.json",
  )
  let weapon_info = match weapon_node {
    { "info": Object(info), .. } => info
    _ => Map([])
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
fn snapshot_afterimage_case(
  item_id : Int,
  stance : @char_stance.StanceId,
  stance_key : String,
  after_image_name : String,
  facing_right : Bool,
  host_shift_x : Double,
  snapshot_path : String,
  diagnose : (
    CharacterRenderState,
    Int,
    @struct.Rectangle[Int],
    Array[RenderSpriteState],
  ) -> Unit raise,
) -> Unit raise {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  let app = @app.App()
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
    )
  @capture_app.ensure_native_context(width=220, height=220)
  let host = @entity.Entity()
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

  let after_images = @char_look.load_after_images(after_image_name)
  @char_look.set_after_images(after_image_name, after_images)

  let collection = @char_look.AfterImage::get_collection(after_image_name, 0)
  guard collection.get(stance_key) is Some(resource) else {
    fail("missing stance_key \{stance_key} in afterimage \{after_image_name}")
  }

  @char_look.add_after_image(after_image_host, look, resource, facing_right)

  let mut ticks = 0
  while look.get_frame() < resource.first_frame && ticks < 60 {
    app.run_frames(1, raw_delta=0.016)
    ticks = ticks + 1
  }
  assert_true(look.get_frame() >= resource.first_frame)

  let capture = @capture_app.capture_after_frames(
    app,
    3,
    width=220,
    height=220,
    raw_delta=0.016,
  )
  diagnose(
    character_render_state(look),
    resource.first_frame,
    resource.range,
    render_sprite_state(capture),
  )
  @capture_app.snapshot(snapshot_path, capture.png)
}
