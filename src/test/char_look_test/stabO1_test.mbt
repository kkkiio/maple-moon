///|
async test "character stabO1" {
  // Initialize test app
  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(200.0)
    .with_canvas_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
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
  look.set_stance(StanceId::STABO1)
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

  // Frame 0
  @capture_app.run_loop(0.016)
  let buffer0 = @capture_app.to_buffer().to_bytes()
  @fs.create_dir("src/test/char_look_test/__snapshot__")
  @fs.write_bytes_to_file(
    "src/test/char_look_test/__snapshot__/stabO1_0.png", buffer0,
  )
  let sprites : Array[@test_snapshots.DebugSprite] = @sprite.sprites
    .iter()
    .map(fn(it) { @test_snapshots.DebugSprite(it.1) })
    .collect()
  @json.inspect(sprites, content=[
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Hair/00030000.img.png",
            "size": [35, 20],
            "pivot": [22, 61],
          },
          "loop_": false,
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
            "pivot": [21, 57],
          },
          "loop_": false,
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
            "pivot": [23, 63],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00002000.img_stabO1_arm.png",
            "size": [26, 18],
            "pivot": [0, 28],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00002000.img_stabO1_body.png",
            "size": [39, 29],
            "pivot": [30, 29],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00012000.img_stabO1_head.png",
            "size": [39, 35],
            "pivot": [23, 61],
          },
          "loop_": false,
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
            "pivot": [20, 45],
          },
          "loop_": true,
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
            "sprite_path": "character/weapon/01302000.img_stabO1.png",
            "size": [43, 8],
            "pivot": [24, 18],
          },
          "loop_": false,
        },
      ],
      "zindex": 70036,
      "visible": true,
    },
  ])

  // still frame 0
  @capture_app.run_loop(0.1)
  // let buffer1 = @capture_app.to_buffer().to_bytes()
  // assert_eq(buffer0, buffer1, msg="frame 0 not sync")
  let sprites1 : Array[@test_snapshots.DebugSprite] = @sprite.sprites
    .iter()
    .map(fn(it) { @test_snapshots.DebugSprite(it.1) })
    .collect()
  assert_eq(sprites.to_json(), sprites1.to_json())

  // Frame 1
  for i = 0; i < 4; i = i + 1 {
    @capture_app.run_loop(0.1)
  }
  let buffer = @capture_app.to_buffer().to_bytes()
  @fs.write_bytes_to_file(
    "src/test/char_look_test/__snapshot__/stabO1_1.png", buffer,
  )
  let sprites = @sprite.sprites
    .iter()
    .map(fn(it) { @test_snapshots.DebugSprite(it.1) })
    .collect()
  @json.inspect(sprites, content=[
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Hair/00030000.img.png",
            "size": [35, 20],
            "pivot": [41, 58],
          },
          "loop_": false,
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
            "pivot": [40, 54],
          },
          "loop_": false,
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
            "pivot": [42, 60],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00002000.img_stabO1_arm.png",
            "size": [26, 18],
            "offset": [26, 0],
            "pivot": [44, 27],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00002000.img_stabO1_body.png",
            "size": [39, 29],
            "offset": [39, 0],
            "pivot": [30, 29],
          },
          "loop_": false,
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
            "sprite_path": "Character/Body/00012000.img_stabO1_head.png",
            "size": [39, 35],
            "offset": [39, 0],
            "pivot": [42, 58],
          },
          "loop_": false,
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
            "pivot": [39, 42],
          },
          "loop_": true,
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
            "sprite_path": "character/weapon/01302000.img_stabO1.png",
            "size": [43, 8],
            "offset": [43, 0],
            "pivot": [72, 26],
          },
          "loop_": false,
        },
      ],
      "zindex": 70036,
      "visible": true,
    },
  ])
}
