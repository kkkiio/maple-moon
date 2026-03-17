///|
using @char_look {type NxStanceLooks}

///|
using @types {type NxStanceBody}

///|
async test "character stand1" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
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
  look.set_stance(StanceId::STAND1)
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
    _ => Map::new()
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
    _ => Map::new()
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
    _ => Map::new()
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
  // Initialize test app and run one loop
  @capture_app.init_app(
    @app.App::new()
    .with_viewport_width(200.0)
    .with_viewport_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )
  @capture_app.run_loop(0.016)
  @capture_app.snapshot("src/test/char_look_test/__snapshot__/stand1.png")
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
            "sprite_path": "Character/Body/00002000.img_stand1_arm.png",
            "size": [11, 19],
            "pivot": [1, 29],
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
            "sprite_path": "Character/Body/00002000.img_stand1_body.png",
            "size": [23, 31],
            "pivot": [18, 31],
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
            "sprite_path": "Character/Body/00012000.img_stand1_head.png",
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
            "sprite_path": "character/weapon/01302000.img_stand1.png",
            "size": [41, 13],
            "pivot": [27, 17],
          },
          "loop_": true,
        },
      ],
      "zindex": 70036,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Coat/01040002.img.png",
            "size": [14, 14],
            "offset": [910, 0],
            "pivot": [11, 31],
          },
          "loop_": true,
        },
      ],
      "zindex": 70014,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Coat/01040002.img.png",
            "size": [5, 7],
            "offset": [924, 0],
            "pivot": [-1, 29],
          },
          "loop_": true,
        },
      ],
      "zindex": 70034,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Pants/01060002.img.png",
            "size": [16, 11],
            "offset": [697, 0],
            "pivot": [12, 21],
          },
          "loop_": true,
        },
      ],
      "zindex": 70012,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Character/Shoes/01072001.img.png",
            "size": [20, 9],
            "offset": [930, 0],
            "pivot": [15, 9],
          },
          "loop_": true,
        },
      ],
      "zindex": 70008,
      "visible": true,
    },
  ])
}
