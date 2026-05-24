///|
priv struct ExplorerCreationUIResource {
  male_choices : LookChoices
  female_choices : LookChoices
  sky : @ms_animation.Picture
  cloud : @ms_animation.Picture
  nameboard : @ms_animation.Picture
  board_gender_top : @ms_animation.Animation
  board_gender_mid : @ms_animation.Animation
  board_gender_bottom : @ms_animation.Animation
  board_char_set : @ms_animation.Animation
  back14 : @ms_animation.Animation
  signboard2 : @ms_animation.Animation
  bt_gender_male : @ui.MapleButtonResource
  bt_gender_female : @ui.MapleButtonResource
  bt_left : @ui.MapleButtonResource
  bt_right : @ui.MapleButtonResource
  bt_yes : @ui.MapleButtonResource
  bt_no : @ui.MapleButtonResource
  avatar_sel : Array[@ms_animation.Animation]
}

///|
fn get_etc_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "Etc",
    loader=@resource.DirResourceLoader::new("assets/Etc"),
  )
}

///|
fn get_map001_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "map001",
    loader=@resource.CompositeAsyncResourceLoader::new({
      "Back/": @resource.DirResourceLoader::new("assets/Map001/Back"),
    }),
  )
}

///|
fn get_login_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "Login",
    loader=@resource.DirResourceLoader::new("assets/UI"),
  )
}

///|
fn parse_choice_values(json : Json) -> Array[Int] {
  guard json is Object(obj) else { abort("expected choice object") }
  let values = []
  for _, value in obj {
    values.push(
      @json.from_json(value) catch {
        _ => abort("invalid choice value")
      },
    )
  }
  values
}

///|
fn parse_choices(json : Json) -> LookChoices {
  guard json is Object(obj) else {
    abort("expected MakeCharInfo choice object")
  }
  let faces = obj.get("0").map_or([], parse_choice_values)
  let hairs = obj.get("1").map_or([], parse_choice_values)
  let haircolors = obj.get("2").map_or([], parse_choice_values)
  let skins = obj.get("3").map_or([], parse_choice_values)
  let tops = obj.get("4").map_or([], parse_choice_values)
  let bots = obj.get("5").map_or([], parse_choice_values)
  let shoes = obj.get("6").map_or([], parse_choice_values)
  let weapons = obj.get("7").map_or([], parse_choice_values)
  guard !faces.is_empty() &&
    !hairs.is_empty() &&
    !haircolors.is_empty() &&
    !skins.is_empty() &&
    !tops.is_empty() &&
    !bots.is_empty() &&
    !shoes.is_empty() &&
    !weapons.is_empty() else {
    abort("MakeCharInfo choices are incomplete")
  }
  { faces, hairs, haircolors, skins, tops, bots, shoes, weapons }
}

///|
fn json_to_picture(json : Json, label : String) -> @ms_animation.Picture {
  let texture : @resource.NxTexture = @json.from_json(json) catch {
    _ => abort("invalid \{label} texture")
  }
  @ms_animation.from_nx_texture(texture)
}

///|
fn json_to_animation(json : Json, label : String) -> @ms_animation.Animation {
  let animation : @resource.NxAnimation = @json.from_json(json) catch {
    _ => abort("invalid animation resource: \{label}")
  }
  @ms_animation.from_nx_animation(animation)
}

///|
fn load_button_visual(json : Json, label : String) -> @ui.NxMapleButton {
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
  @json.from_json(normalized) catch {
    _ => abort("invalid button resource: \{label}")
  }
}

///|
fn require_field(json : Json, key : String) -> Json {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(value) => value
        None => abort("missing \{key}")
      }
    _ => abort("expected object with \{key}")
  }
}

///|
fn load_resource() -> ExplorerCreationUIResource {
  let login_loader = get_login_loader()
  let mkinfo = get_etc_loader().require_resource(["MakeCharInfo.img", "Info"])
  let male_choices = match mkinfo {
    { "CharMale": Object(_) as char_male, .. } => parse_choices(char_male)
    _ => abort("missing CharMale choices")
  }
  let female_choices = match mkinfo {
    { "CharFemale": Object(_) as char_female, .. } => parse_choices(char_female)
    _ => abort("missing CharFemale choices")
  }
  let map001_loader = get_map001_loader()
  let customize_char_src = login_loader.require_resource([
    "Login.img", "CustomizeChar", "000",
  ])
  let signboard2_src = @resource.require_async_loader("map_latest").require_resource([
      "Obj", "login.img", "NewChar", "signboard", "2",
    ],
  )
  let board_src = match customize_char_src {
    { "board": Object(_) as board_src, .. } => board_src
    _ => abort("missing board")
  }
  let gender_select_src = match customize_char_src {
    { "genderSelect": Object(_) as gender_select_src, .. } => gender_select_src
    _ => abort("missing genderSelect")
  }
  let sky_src = map001_loader.require_resource([
    "Back", "login.img", "back", "2",
  ])
  let cloud_src = map001_loader.require_resource([
    "Back", "login.img", "back", "27",
  ])
  let back14_src = map001_loader.require_resource([
    "Back", "login.img", "back", "14",
  ])
  let sky_texture : @resource.NxTexture = @json.from_json(sky_src) catch {
    _ => abort("invalid sky texture")
  }
  let sky = @ms_animation.from_nx_texture(
    sky_texture,
    size=@selene_math.Vec2(800.0, 400.0),
    repeat=@selene_math.Repeat,
  )
  let cloud = json_to_picture(cloud_src, "cloud")
  let avatar_sel : Array[@ms_animation.Animation] = []
  let avatar_sel_src = match customize_char_src {
    { "avatarSel": Object(_) as avatar_sel_src, .. } => avatar_sel_src
    _ => abort("missing avatarSel")
  }
  guard avatar_sel_src is Object(avatar_sel_obj) else {
    abort("invalid avatarSel")
  }
  for i = 0; i <= 5; i = i + 1 {
    let anim_json = avatar_sel_obj.get(i.to_string()).unwrap_or(Json::null())
    let normal_json = match anim_json {
      { "normal": normal, .. } => normal
      _ => abort("missing avatarSel normal")
    }
    avatar_sel.push(json_to_animation(normal_json, "avatarSel normal"))
  }
  {
    male_choices,
    female_choices,
    sky,
    cloud,
    board_gender_top: json_to_animation(
      require_field(board_src, "genderTop"),
      "genderTop",
    ),
    board_gender_mid: json_to_animation(
      require_field(board_src, "boardMid"),
      "boardMid",
    ),
    board_gender_bottom: json_to_animation(
      require_field(board_src, "boardBottom"),
      "boardBottom",
    ),
    board_char_set: json_to_animation(
      require_field(customize_char_src, "charSet"),
      "charSet",
    ),
    back14: json_to_animation(back14_src, "back14"),
    signboard2: json_to_animation(signboard2_src, "signboard2"),
    bt_gender_male: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match gender_select_src {
          { "male": male, .. } => male
          _ => abort("missing male button")
        },
        "male",
      ),
    ),
    bt_gender_female: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match gender_select_src {
          { "female": female, .. } => female
          _ => abort("missing female button")
        },
        "female",
      ),
    ),
    bt_left: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtLeft": bt_left, .. } => bt_left
          _ => abort("missing BtLeft")
        },
        "BtLeft",
      ),
    ),
    bt_right: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtRight": bt_right, .. } => bt_right
          _ => abort("missing BtRight")
        },
        "BtRight",
      ),
    ),
    bt_yes: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtYes": bt_yes, .. } => bt_yes
          _ => abort("missing BtYes")
        },
        "BtYes",
      ),
    ),
    bt_no: @ui.MapleButtonResource::from_nx(
      load_button_visual(
        match customize_char_src {
          { "BtNo": bt_no, .. } => bt_no
          _ => abort("missing BtNo")
        },
        "BtNo",
      ),
    ),
    nameboard: json_to_picture(
      match customize_char_src {
        { "charName": char_name, .. } => char_name
        _ => abort("missing charName")
      },
      "charName",
    ),
    avatar_sel,
  }
}
