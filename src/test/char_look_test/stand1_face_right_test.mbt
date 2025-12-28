///|
async test "character stand1 face right" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
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
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @fs.read_file_to_string(
      "assets/Character/Hair/00030000.img.json",
    )
    |> @json.parse
    |> @json.from_json
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
    @char_look.Face::new(
      20000,
      @fs.read_file_to_string("assets/Character/Face/00020000.img.json")
      |> @json.parse,
    ),
    draw_info,
  )
  look.set_stance(@types.StanceId::STAND1)
  look.set_facing_right(true)
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
  // Initialize test app and run one loop
  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(200.0)
    .with_canvas_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )
  @capture_app.run_loop(0.016)
  let buffer = @capture_app.to_buffer().to_bytes()
  @fs.create_dir("src/test/char_look_test/__snapshot__")
  @fs.write_bytes_to_file(
    "src/test/char_look_test/__snapshot__/stand1_face_right.png", buffer,
  )
  let sprites = @sprite.sprites
    .iter()
    .map(fn(it) { @char_look_test.DebugSprite(it.1) })
  @json.inspect(sprites, content=[
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Hair/00030000.img.png",
            "size": [35, 20],
            "pivot": [22, 64],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70016,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Hair/00030000.img.png",
            "size": [33, 17],
            "offset": [73, 0],
            "pivot": [21, 60],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70020,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Hair/00030000.img.png",
            "size": [38, 22],
            "offset": [35, 0],
            "pivot": [23, 66],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70025,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Body/00002000.img_stand1_arm.png",
            "size": [11, 19],
            "pivot": [1, 29],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70035,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Body/00002000.img_stand1_body.png",
            "size": [23, 31],
            "pivot": [18, 31],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70005,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Body/00012000.img_stand1_head.png",
            "size": [39, 35],
            "pivot": [23, 64],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70019,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Face/00020000.img_default_face.png",
            "size": [26, 16],
            "pivot": [20, 48],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70021,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "character/weapon/01302000.img_stand1.png",
            "size": [41, 13],
            "pivot": [27, 17],
          },
          "loop_": true,
          "transform": { "a": -1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0 },
        },
      ],
      "zindex": 70036,
      "visible": true,
    },
  ])
}
