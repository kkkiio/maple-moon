///|
test "damage number" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  // 'No' for Number
  let no_red_1 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoRed1.json"),
    ),
  )
  let no_red_0 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoRed0.json"),
    ),
  )
  let no_cri_1 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoCri1.json"),
    ),
  )
  let no_cri_0 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoCri0.json"),
    ),
  )
  let no_violet_1 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoViolet1.json"),
    ),
  )
  let no_violet_0 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoViolet0.json"),
    ),
  )
  let no_blue_1 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoBlue1.json"),
    ),
  )
  let no_blue_0 : DamageSkin = @json.from_json(
    @json.parse(
      @fs.read_file_to_string("assets/Effect/BasicEff.img/NoBlue0.json"),
    ),
  )
  let red_skins : Skins = Skins::{ big: no_red_1, small: no_red_0 }
  let cri_skins : Skins = Skins::{ big: no_cri_1, small: no_cri_0 }
  let violet_skins : Skins = Skins::{ big: no_violet_1, small: no_violet_0 }
  let blue_skins : Skins = Skins::{ big: no_blue_1, small: no_blue_0 }
  let number_set = NumberSet::{ red_skins, cri_skins, violet_skins, blue_skins }
  number_set.show_number(HIT_NORMAL, 100, 0)
  let sprites = @sprite.sprites()
    .iter()
    .map(fn(it) { @test_snapshots.DebugSprite(it.1) })
    .collect()
  json_inspect(sprites, content=[
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Effect/BasicEff.img/NoRed1.png",
            "size": [37, 39],
            "offset": [37, 0],
            "pivot": [18, 38],
          },
          "loop_": false,
        },
      ],
      "zindex": 75000,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Effect/BasicEff.img/NoRed0.png",
            "size": [31, 33],
            "pivot": [15, 32],
          },
          "loop_": false,
        },
      ],
      "zindex": 75000,
      "visible": true,
    },
    {
      "draw": [
        "Animation",
        {
          "current": {
            "sprite_path": "Effect/BasicEff.img/NoRed0.png",
            "size": [31, 33],
            "pivot": [15, 32],
          },
          "loop_": false,
        },
      ],
      "zindex": 75000,
      "visible": true,
    },
  ])
}
