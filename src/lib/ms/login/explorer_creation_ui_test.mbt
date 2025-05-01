test "explorer creation ui" {
  let resource : ExplorerCreatorUIResource = {
    male_choices: {
      faces: [20000, 20001],
      hairs: [30000, 30040],
      haircolors: [0, 7],
      skins: [0, 1],
      tops: [1040002, 1040006],
      bots: [1060002, 1060008],
      shoes: [1072001, 1072005],
      weapons: [1302000, 1322005],
    },
    female_choices: {
      faces: [21000, 21001],
      hairs: [31000, 31040],
      haircolors: [0, 7],
      skins: [0, 1],
      tops: [1041002, 1041006],
      bots: [1061002, 1061008],
      shoes: [1072001, 1072005],
      weapons: [1302000, 1322005],
    },
    sky: @graphics.Texture::default(),
    cloud: @graphics.Texture::default(),
    nameboard: @graphics.Texture::default(),
    board_gender_top: @graphics.Animation::default(),
    board_gender_mid: @graphics.Animation::default(),
    board_gender_bottom: @graphics.Animation::default(),
    board_char_set: @graphics.Animation::default(),
    back14: @graphics.Animation::default(),
    signboard2: @graphics.Animation::default(),
    bt_gender_male: @ui.MapleButtonResource::default(),
    bt_gender_female: @ui.MapleButtonResource::default(),
    bt_left: @ui.MapleButtonResource::default(),
    bt_right: @ui.MapleButtonResource::default(),
    bt_yes: @ui.MapleButtonResource::default(),
    bt_no: @ui.MapleButtonResource::default(),
    avatar_sel: [],
  }
  let ui = ExplorerCreatorUI::new(resource, @ui.Hooks::default(), fn(_, _) {  })
  let rs = ui.render()
  @json.inspect!(rs, content={
    "render_units": [
      {},
      {},
      {
        "drawable": {
          "texture": {
            "bitmap": Json::Null,
            "origin": [0, 0],
            "dimensions": [0, 0],
          },
          "rows": 2,
          "cols": 2147483647,
          "row_height": 400,
          "col_width": 0,
        },
        "pos": [0, -100],
      },
      {
        "texture": {
          "bitmap": Json::Null,
          "origin": [0, 0],
          "dimensions": [0, 0],
        },
        "x": 200,
      },
      {},
      {},
      {},
      {},
      {},
    ],
  })
}
