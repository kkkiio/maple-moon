///|
priv struct ExplorerCreationUIResource {
  male_choices : LookChoices
  female_choices : LookChoices
  sky : @sprite.Picture
  cloud : @sprite.Picture
  nameboard : @sprite.Picture
  board_gender_top : @sprite.Animation
  board_gender_mid : @sprite.Animation
  board_gender_bottom : @sprite.Animation
  board_char_set : @sprite.Animation
  back14 : @sprite.Animation
  signboard2 : @sprite.Animation
  bt_gender_male : @ui.MapleButtonResource
  bt_gender_female : @ui.MapleButtonResource
  bt_left : @ui.MapleButtonResource
  bt_right : @ui.MapleButtonResource
  bt_yes : @ui.MapleButtonResource
  bt_no : @ui.MapleButtonResource
  avatar_sel : Array[@sprite.Animation]
}

///|
fn get_etc_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "Etc",
    loader=@resource.DirResourceLoader::new("/assets/Etc"),
    base_url="/assets",
  )
}

///|
fn get_map001_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "map001",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Back/": @resource.DirResourceLoader::new("/assets/Map001/Back"),
    }),
    base_url="/assets",
  )
}

///|
fn get_login_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "Login",
    loader=@resource.DirResourceLoader::new("/assets/UI"),
    base_url="/assets",
  )
}

///|
fn parse_choice_values(json : Json) -> Array[Int] raise {
  guard json is Object(obj) else { fail("expected choice object") }
  let values = []
  for _, value in obj {
    values.push(@json.from_json(value))
  }
  values
}

///|
fn parse_choices(json : Json) -> LookChoices raise {
  guard json is Object(obj) else { fail("expected MakeCharInfo choice object") }
  let faces = obj.get("0").map_or([], parse_choice_values)
  let hairs = obj.get("1").map_or([], parse_choice_values)
  let haircolors = obj.get("2").map_or([], parse_choice_values)
  let skins = obj.get("3").map_or([], parse_choice_values)
  let tops = obj.get("4").map_or([], parse_choice_values)
  let bots = obj.get("5").map_or([], parse_choice_values)
  let shoes = obj.get("6").map_or([], parse_choice_values)
  let weapons = obj.get("7").map_or([], parse_choice_values)
  guard not(faces.is_empty()) &&
    not(hairs.is_empty()) &&
    not(haircolors.is_empty()) &&
    not(skins.is_empty()) &&
    not(tops.is_empty()) &&
    not(bots.is_empty()) &&
    not(shoes.is_empty()) &&
    not(weapons.is_empty()) else {
    fail("MakeCharInfo choices are incomplete")
  }
  { faces, hairs, haircolors, skins, tops, bots, shoes, weapons }
}

///|
fn json_to_picture(json : Json) -> @sprite.Picture raise {
  let texture : @resource.NxTexture = @json.from_json(json)
  @resource.nx_texture_to_selene_picture(texture)
}

///|
fn load_button_visual(json : Json) -> @ui.NxMapleButton raise {
  let normalized : Json = match json {
    { "normal": normal, "mouseOver": mouse_over, "pressed": pressed, .. } =>
      {
        "normal": normal,
        "mouseOver": mouse_over,
        "pressed": pressed,
        "disabled": match json {
          { "disabled": disabled, .. } => disabled
          _ => normal
        },
      }
    _ => json
  }
  @json.from_json(normalized)
}

///|
async fn load_resource() -> ExplorerCreationUIResource {
  let login_loader = get_login_loader()
  let mkinfo = get_etc_loader().load_resource(["MakeCharInfo.img", "Info"])
  let male_choices = match mkinfo {
    { "CharMale": Object(_) as char_male, .. } => parse_choices(char_male)
    _ => fail("missing CharMale choices")
  }
  let female_choices = match mkinfo {
    { "CharFemale": Object(_) as char_female, .. } => parse_choices(char_female)
    _ => fail("missing CharFemale choices")
  }
  let map001_loader = get_map001_loader()
  let customize_char_src = login_loader.load_resource([
    "Login.img", "CustomizeChar", "000",
  ])
  let signboard2_src = @resource.get_map_latest_loader().load_resource([
    "Obj", "login.img", "NewChar", "signboard", "2",
  ])
  let board_src = match customize_char_src {
    { "board": Object(_) as board_src, .. } => board_src
    _ => fail("missing board")
  }
  let gender_select_src = match customize_char_src {
    { "genderSelect": Object(_) as gender_select_src, .. } => gender_select_src
    _ => fail("missing genderSelect")
  }
  let sky_src = map001_loader.load_resource(["Back", "login.img", "back", "2"])
  let cloud_src = map001_loader.load_resource([
    "Back", "login.img", "back", "27",
  ])
  let back14_src = map001_loader.load_resource([
    "Back", "login.img", "back", "14",
  ])
  let sky_texture : @resource.NxTexture = @json.from_json(sky_src)
  let sky = @resource.nx_texture_to_selene_picture(
    sky_texture,
    size=@selene_math.Vec2D(800.0, 400.0),
    repeat=@selene_math.Repeat,
  )
  let cloud = json_to_picture(cloud_src)
  let avatar_sel : Array[@sprite.Animation] = []
  let avatar_sel_src = match customize_char_src {
    { "avatarSel": Object(_) as avatar_sel_src, .. } => avatar_sel_src
    _ => fail("missing avatarSel")
  }
  guard avatar_sel_src is Object(avatar_sel_obj) else {
    fail("invalid avatarSel")
  }
  for i = 0; i <= 5; i = i + 1 {
    let anim_json = avatar_sel_obj.get(i.to_string()).unwrap_or(Json::null())
    let normal_json = match anim_json {
      { "normal": normal, .. } => normal
      _ => fail("missing avatarSel normal")
    }
    avatar_sel.push(
      @resource.nx_animation_to_selene_animation(@json.from_json(normal_json)),
    )
  }
  {
    male_choices,
    female_choices,
    sky,
    cloud,
    board_gender_top: @resource.nx_animation_to_selene_animation(
      @json.from_json(
        match board_src {
          { "genderTop": gender_top, .. } => gender_top
          _ => fail("missing genderTop")
        },
      ),
    ),
    board_gender_mid: @resource.nx_animation_to_selene_animation(
      @json.from_json(
        match board_src {
          { "boardMid": board_mid, .. } => board_mid
          _ => fail("missing boardMid")
        },
      ),
    ),
    board_gender_bottom: @resource.nx_animation_to_selene_animation(
      @json.from_json(
        match board_src {
          { "boardBottom": board_bottom, .. } => board_bottom
          _ => fail("missing boardBottom")
        },
      ),
    ),
    board_char_set: @resource.nx_animation_to_selene_animation(
      @json.from_json(
        match customize_char_src {
          { "charSet": char_set, .. } => char_set
          _ => fail("missing charSet")
        },
      ),
    ),
    back14: @resource.nx_animation_to_selene_animation(
      @json.from_json(back14_src),
    ),
    signboard2: @resource.nx_animation_to_selene_animation(
      @json.from_json(signboard2_src),
    ),
    bt_gender_male: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match gender_select_src {
          { "male": male, .. } => male
          _ => fail("missing male button")
        },
      ),
    ),
    bt_gender_female: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match gender_select_src {
          { "female": female, .. } => female
          _ => fail("missing female button")
        },
      ),
    ),
    bt_left: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtLeft": bt_left, .. } => bt_left
          _ => fail("missing BtLeft")
        },
      ),
    ),
    bt_right: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtRight": bt_right, .. } => bt_right
          _ => fail("missing BtRight")
        },
      ),
    ),
    bt_yes: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtYes": bt_yes, .. } => bt_yes
          _ => fail("missing BtYes")
        },
      ),
    ),
    bt_no: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtNo": bt_no, .. } => bt_no
          _ => fail("missing BtNo")
        },
      ),
    ),
    nameboard: json_to_picture(
      match customize_char_src {
        { "charName": char_name, .. } => char_name
        _ => fail("missing charName")
      },
    ),
    avatar_sel,
  }
}
