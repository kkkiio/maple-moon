// No using here to avoid duplicate declaration in the same package

///|
async test "character with crossbow equipment" {
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

  look.set_stance(StanceId::STAND2)
  look.set_pos(Vec2D(100.0, 100.0))

  // Add Crossbow (Item ID 1462000)
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/01462000.img.json",
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

  // Initialize test app and run one loop
  @capture_app.init_app(
    @app.App::new()
    .with_viewport_width(200.0)
    .with_viewport_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )
  @capture_app.run_loop(0.016)

  // Snapshot
  @capture_app.snapshot(
    "src/test/char_look_test/__snapshot__/crossbow_stand1.png",
    img_description="A character stands facing left, holding a purple and golden crossbow. The weapon is held upright by its purple stock, and its curved golden limbs are visible near the character's upper back/shoulder area.",
  )

  let sprites = @sprite.sprites()
    .iter()
    .map(fn(it) { @test_snapshots.DebugSprite(it.1) })
  json_inspect(sprites, content=[
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
            "sprite_path": "Character/Body/00002000.img_stand2_arm.png",
            "size": [10, 13],
            "pivot": [4, 29],
          },
          "loop_": true,
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
            "sprite_path": "Character/Body/00002000.img_stand2_body.png",
            "size": [20, 31],
            "pivot": [15, 31],
          },
          "loop_": true,
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
            "sprite_path": "Character/Body/00002000.img_stand2_hand.png",
            "size": [19, 24],
            "pivot": [18, 26],
          },
          "loop_": true,
        },
      ],
      "zindex": 70048,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Body/00012000.img_stand2_head.png",
            "size": [39, 35],
            "pivot": [23, 64],
          },
          "loop_": true,
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
            "sprite_path": "/Character/Weapon/spritesheets/01462000.img.png",
            "size": [39, 39],
            "offset": [39, 114],
            "pivot": [23, 43],
          },
          "loop_": true,
        },
      ],
      "zindex": 70037,
      "visible": true,
    },
  ])
}
