///|
fn parse_json_file(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
fn make_test_look(weapon_item_id : Int?) -> @char_look.CharLook raise {
  let entity = @entity.Entity::new()
  let bodynode = parse_json_file("assets/Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = parse_json_file("assets/Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    parse_json_file("assets/Character/Hair/00030000.img.json"),
  )
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
      parse_json_file("assets/Character/Face/00020000.img.json"),
    ),
    draw_info,
  )
  match weapon_item_id {
    Some(item_id) => {
      let weapon_path = "assets/Character/Weapon/\{@utils.stoi_left_pad0(item_id, 8)}.img.json"
      let weapon_node = parse_json_file(weapon_path)
      let info_map = match weapon_node {
        { "info": Object(info), .. } => info
        _ => panic()
      }
      let icon = match info_map.get("icon") {
        Some(v) => @json.from_json(v)
        None => panic()
      }
      let icon_raw = match info_map.get("iconRaw") {
        Some(v) => @json.from_json(v)
        None => panic()
      }
      let weapon_item = @item.ItemData::{
        src: weapon_node,
        icons: (icon, icon_raw),
        item_id,
        price: 0,
        gender: 0,
        name: "TestWeapon",
        desc: "",
        category: "Weapon",
        valid: true,
        untradable: false,
        unique: false,
        unsellable: false,
        cash_item: false,
      }
      look.add_equip(weapon_item, @slot.Id::WEAPON)
    }
    None => ()
  }
  look
}

///|
fn make_test_character(
  oid : Int,
  weapon_item_id : Int?,
) -> @character.Character raise {
  let look = make_test_look(weapon_item_id)
  let stats : @char_stats.CharStats = @char_stats.CharStats::new(
    @server_proto.StatsEntry::default(),
    fn() {
      look
      .get_equips()
      .get_weapon()
      .map(fn(w) { w.get_type() })
      .unwrap_or(@weapon.Type::NONE)
    },
    @job.Job::new(0, @job.Level::BEGINNER, Map::new()),
    Map::new(),
    Map::new(),
    Map::new(),
  )
  @character.Character::new(
    look.get_root_entity(),
    oid,
    look,
    "PassiveTestCharacter",
    get_skilllevel=fn(_) { 0 },
    stats,
  )
}

///|
fn make_test_player(oid : Int, weapon_item_id : Int?) -> @player.Player raise {
  let look = make_test_look(weapon_item_id)
  let stats : @char_stats.CharStats = @char_stats.CharStats::new(
    @server_proto.StatsEntry::default(),
    fn() {
      look
      .get_equips()
      .get_weapon()
      .map(fn(w) { w.get_type() })
      .unwrap_or(@weapon.Type::NONE)
    },
    @job.Job::new(0, @job.Level::BEGINNER, Map::new()),
    Map::new(),
    Map::new(),
    Map::new(),
  )
  let inventory = @legacy_types.MockInventory::default()
  let player = @player.Player::new(
    look.get_root_entity(),
    oid,
    "PassiveTestPlayer",
    inventory,
    look,
    stats,
  )
  @player.set_player(player)
  player
}

///|
fn make_final_attack_test_ctx(
  attacker : @character.Character?,
  trigger_count : Ref[Int],
  randomizer : @random.Rand,
  skill_level : Int,
  skill_data : @skill.SkillData?,
) -> PassiveContext {
  PassiveContext::{
    randomizer,
    get_character_fn: fn(oid) {
      match attacker {
        Some(chr) => if chr.get_oid() == oid { Some(chr) } else { None }
        None => None
      }
    },
    get_skill_level_fn: fn(_attacker_oid, _skill_id) { skill_level },
    get_skill_data_fn: fn(_skill_id) { skill_data },
    trigger_extra_attack_fn: fn(_attacker_oid, _skill_id, _targets) {
      trigger_count.val += 1
    },
  }
}

///|
fn make_hit_event(source : @combat_system.HitSource) -> @combat_system.HitEvent {
  {
    attacker_oid: 1,
    move_id: 100,
    source,
    target_oids: [101],
    result: @combat_proto.AttackResult::default(),
  }
}

///|
async test "sword_fa_fighter_triggers_with_sword_1h" {
  @resource.set_skill_loader(
    @resource.AsyncLoader::new(
      "test_local_skill",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new("assets/Skill"),
    ),
  )
  @resource.set_string_loader(
    @resource.AsyncLoader::new(
      "test_local_string",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new("assets/String"),
    ),
  )
  let player = try! make_test_player(1, Some(1302000))
  let attacker = player.get_character()
  let trigger_count = Ref::new(0)
  let passive = SwordFaFighterPassive::default()
  let skill_id = @skill.SkillId::SWORD_FA_FIGHTER.int_value()
  let skill_data = Some(@skill.SkillData::load(skill_id))
  let ctx = make_final_attack_test_ctx(
    Some(attacker),
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    skill_data,
  )
  for _ in 0..<2000 {
    passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::UserInput))
  }
  assert_true(trigger_count.val > 0)
}

///|
test "sword_fa_fighter_does_not_trigger_with_axe_1h" {
  let player = try! make_test_player(1, Some(1312001))
  let attacker = player.get_character()
  let trigger_count = Ref::new(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    Some(attacker),
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    None,
  )
  for _ in 0..<2000 {
    passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::UserInput))
  }
  assert_eq(trigger_count.val, 0)
}

///|
test "sword_fa_fighter_does_not_trigger_with_sword_2h" {
  let player = try! make_test_player(1, Some(1402000))
  let attacker = player.get_character()
  let trigger_count = Ref::new(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    Some(attacker),
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    None,
  )
  for _ in 0..<2000 {
    passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::UserInput))
  }
  assert_eq(trigger_count.val, 0)
}

///|
test "sword_fa_fighter_does_not_trigger_when_attacker_missing" {
  let trigger_count = Ref::new(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    None,
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    None,
  )
  passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::UserInput))
  assert_eq(trigger_count.val, 0)
}

///|
test "sword_fa_fighter_does_not_trigger_for_passive_source" {
  let player = try! make_test_player(1, Some(1302000))
  let attacker = player.get_character()
  let trigger_count = Ref::new(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    Some(attacker),
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    None,
  )
  passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::Passive(99999)))
  assert_eq(trigger_count.val, 0)
}

///|
test "character_registry_lifecycle" {
  @character.clear_character_registry()
  let character = try! make_test_character(77, None)
  let oid = character.get_oid()
  assert_true(@character.get_character_by_oid(oid) is None)

  @character.register_character(character)
  assert_true(@character.get_character_by_oid(oid) is Some(_))

  @character.unregister_character_by_oid(oid)
  assert_true(@character.get_character_by_oid(oid) is None)

  @character.register_character(character)
  @character.clear_character_registry()
  assert_true(@character.get_character_by_oid(oid) is None)
}
