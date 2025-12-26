///|
using @char_look {type NxStanceLooks}

///|
using @types {type NxStanceBody}

///|

///|
async test "character stand1" {
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
    "src/test/char_look_test/__snapshot__/stand1.png", buffer,
  )
  let sprites = @sprite.sprites
    .iter()
    .map(fn(it) { @char_look_test.TestSprite(it.1) })
  @json.inspect(sprites, content=[
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [35, 20],
              "offset": [35, 33],
              "pivot": [22, 64],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [35, 20],
              "offset": [35, 33],
              "pivot": [22, 64],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [35, 20],
              "offset": [35, 33],
              "pivot": [22, 64],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70016,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [33, 17],
              "offset": [76, 0],
              "pivot": [21, 60],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [33, 17],
              "offset": [76, 0],
              "pivot": [21, 60],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [33, 17],
              "offset": [76, 0],
              "pivot": [21, 60],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70020,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [38, 22],
              "offset": [38, 0],
              "pivot": [23, 66],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [38, 22],
              "offset": [38, 0],
              "pivot": [23, 66],
            },
            {
              "sprite_path": "/assets/character/hair/male_1_white_hair.png",
              "size": [38, 22],
              "offset": [38, 0],
              "pivot": [23, 66],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70025,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "Character/Body/00002000.img_stand1_arm.png",
              "size": [11, 19],
              "pivot": [1, 29],
            },
            {
              "sprite_path": "Character/Body/00002000.img_stand1_arm.png",
              "size": [11, 19],
              "offset": [11, 0],
              "pivot": [0, 29],
            },
            {
              "sprite_path": "Character/Body/00002000.img_stand1_arm.png",
              "size": [11, 19],
              "offset": [22, 0],
              "pivot": [-1, 29],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70035,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "Character/Body/00002000.img_stand1_body.png",
              "size": [23, 31],
              "pivot": [18, 31],
            },
            {
              "sprite_path": "Character/Body/00002000.img_stand1_body.png",
              "size": [23, 31],
              "offset": [23, 0],
              "pivot": [18, 31],
            },
            {
              "sprite_path": "Character/Body/00002000.img_stand1_body.png",
              "size": [23, 31],
              "offset": [46, 0],
              "pivot": [18, 31],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70005,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "Character/Body/00012000.img_stand1_head.png",
              "size": [39, 35],
              "pivot": [23, 64],
            },
            {
              "sprite_path": "Character/Body/00012000.img_stand1_head.png",
              "size": [39, 35],
              "offset": [39, 0],
              "pivot": [23, 64],
            },
            {
              "sprite_path": "Character/Body/00012000.img_stand1_head.png",
              "size": [39, 35],
              "offset": [78, 0],
              "pivot": [23, 64],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70019,
      "visible": true,
    },
    {
      "sprite_type": [
        "Animation",
        {
          "frames": [
            {
              "sprite_path": "character/weapon/01302000.img_stand1.png",
              "size": [41, 13],
              "pivot": [27, 17],
            },
            {
              "sprite_path": "character/weapon/01302000.img_stand1.png",
              "size": [41, 13],
              "offset": [41, 0],
              "pivot": [26, 17],
            },
            {
              "sprite_path": "character/weapon/01302000.img_stand1.png",
              "size": [41, 13],
              "offset": [82, 0],
              "pivot": [25, 17],
            },
          ],
          "loop_": true,
        },
        0,
      ],
      "zindex": 70036,
      "visible": true,
    },
  ])
}
