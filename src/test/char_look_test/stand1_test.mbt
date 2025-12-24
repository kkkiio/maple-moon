///|
using @char_look {type NxStanceLooks}

///|
using @types {type NxStanceBody}

///|

///|
async test "character stand1" {
  let bodynode = @fs.read_file_to_string(
      "assets/Character/Body/00002000.img.json",
    )
    |> @json.parse
  let stance_bodys_map : NxStanceLooks[NxStanceBody] = @json.from_json(bodynode)
  let headnode = @fs.read_file_to_string(
      "assets/Character/Body/00012000.img.json",
    )
    |> @json.parse
  let stance_heads_map : NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    @char_look.male_1_white_hair,
  )
  let entity = @entity.Entity::new()
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
    @char_look.Face::new(20800, @char_look.male_1_white_face),
    draw_info,
  )
  look.set_stance(@types.StanceId::STAND1)
  look.set_pos(Vec2D(100.0, 100.0))
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/01302000.img.json",
    )
    |> @json.parse
  let weapon_info = match weapon_node {
    { "info": Object(info), .. } => info
    _ => Map::new()
  }
  let weapon_icons = (
    weapon_info.get("icon").map(fn(json) { @json.from_json(json) }).unwrap(),
    weapon_info.get("iconRaw").map(fn(json) { @json.from_json(json) }).unwrap(),
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
  // Setup canvas for capture
  let canvas = @capture_canvas.create_canvas(200, 200)
  let ctx = canvas.get_context("2d")
  @capture_canvas.set_canvas(canvas)
  @capture_canvas.set_ctx(ctx)
  @inherit.inherit_position_system(0.016)
  @sprite.render_sprite_system(0.016)
  let buffer = canvas.to_buffer("image/png").to_bytes()
  @fs.create_dir("src/test/char_look_test/__snapshot__")
  @fs.write_bytes_to_file(
    "src/test/char_look_test/__snapshot__/stand1.png", buffer,
  )
}
