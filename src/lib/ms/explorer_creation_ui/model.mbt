///|
using @server_proto {type LookEntry}

///|
enum UiStage {
  ChoosingGender
  CustomizingLook
  ConfirmingName
  Submitting
} derive(Eq)

///|
priv struct LookChoices {
  skins : Array[Int]
  haircolors : Array[Int]
  faces : Array[Int]
  hairs : Array[Int]
  tops : Array[Int]
  bots : Array[Int]
  shoes : Array[Int]
  weapons : Array[Int]
}

///|
priv struct ExplorerLookConfig {
  mut female : Bool
  mut skin_idx : Int
  mut hair_color_idx : Int
  mut face_idx : Int
  mut hair_idx : Int
  mut top_idx : Int
  mut bot_idx : Int
  mut shoe_idx : Int
  mut weapon_idx : Int
} derive(Eq)

///|
priv struct ExplorerCreationModel {
  mut stage : UiStage
  config : ExplorerLookConfig
  mut generated_name : String
  mut error_message : String?
}

///|
fn choices_for_config(
  config : ExplorerLookConfig,
  resource : ExplorerCreationUIResource,
) -> LookChoices {
  if config.female {
    resource.female_choices
  } else {
    resource.male_choices
  }
}

///|
fn random_initial_config(
  female : Bool,
  _randomizer : @random.Rand,
  resource : ExplorerCreationUIResource,
) -> ExplorerLookConfig {
  ignore(resource)
  {
    female,
    skin_idx: 0,
    hair_color_idx: 0,
    face_idx: 0,
    hair_idx: 0,
    top_idx: 0,
    bot_idx: 0,
    shoe_idx: 0,
    weapon_idx: 0,
  }
}

///|
fn new_model(
  randomizer : @random.Rand,
  resource : ExplorerCreationUIResource,
) -> ExplorerCreationModel {
  {
    stage: UiStage::ChoosingGender,
    config: random_initial_config(false, randomizer, resource),
    generated_name: "",
    error_message: None,
  }
}

///|
fn update_config_index(
  model : ExplorerCreationModel,
  resource : ExplorerCreationUIResource,
  part : String,
  step : Int,
) -> Unit {
  let choices = choices_for_config(model.config, resource)
  fn next_idx(current : Int, length : Int) -> Int {
    (current + step + length) % length
  }
  match part {
    "face" =>
      model.config.face_idx = next_idx(
        model.config.face_idx,
        choices.faces.length(),
      )
    "hair" =>
      model.config.hair_idx = next_idx(
        model.config.hair_idx,
        choices.hairs.length(),
      )
    "hair_color" =>
      model.config.hair_color_idx = next_idx(
        model.config.hair_color_idx,
        choices.haircolors.length(),
      )
    "skin" =>
      model.config.skin_idx = next_idx(
        model.config.skin_idx,
        choices.skins.length(),
      )
    "top" =>
      model.config.top_idx = next_idx(
        model.config.top_idx,
        choices.tops.length(),
      )
    "bottom" =>
      model.config.bot_idx = next_idx(
        model.config.bot_idx,
        choices.bots.length(),
      )
    "shoes" =>
      model.config.shoe_idx = next_idx(
        model.config.shoe_idx,
        choices.shoes.length(),
      )
    "weapon" =>
      model.config.weapon_idx = next_idx(
        model.config.weapon_idx,
        choices.weapons.length(),
      )
    _ => abort("unknown part: \{part}")
  }
}

///|
fn config_to_look_entry(
  config : ExplorerLookConfig,
  resource : ExplorerCreationUIResource,
) -> LookEntry {
  let choices = choices_for_config(config, resource)
  {
    female: config.female,
    skin: choices.skins[config.skin_idx],
    faceid: choices.faces[config.face_idx],
    hairid: choices.hairs[config.hair_idx] +
    choices.haircolors[config.hair_color_idx],
    equips: Map::from_array([
      (@slot.Id::TOP.int_value(), choices.tops[config.top_idx]),
      (@slot.Id::BOTTOM.int_value(), choices.bots[config.bot_idx]),
      (@slot.Id::SHOES.int_value(), choices.shoes[config.shoe_idx]),
      (@slot.Id::WEAPON.int_value(), choices.weapons[config.weapon_idx]),
    ]),
    maskedequips: {},
    petids: [],
  }
}

///|
fn config_label_rows(
  config : ExplorerLookConfig,
  resource : ExplorerCreationUIResource,
) -> Array[(String, Int)] {
  let choices = choices_for_config(config, resource)
  [
    ("Face", choices.faces[config.face_idx]),
    ("Hair", choices.hairs[config.hair_idx]),
    ("Hair Color", choices.haircolors[config.hair_color_idx]),
    ("Skin", choices.skins[config.skin_idx]),
    ("Top", choices.tops[config.top_idx]),
    ("Bottom", choices.bots[config.bot_idx]),
    ("Shoes", choices.shoes[config.shoe_idx]),
    ("Weapon", choices.weapons[config.weapon_idx]),
  ]
}
