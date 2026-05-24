///|
fn parse_json_file(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
fn make_test_equips(weapon_item_id : Int?) -> @equip.CharEquips raise {
  let res = @character_presentation.CharacterPresentationResource::load()
  let draw_info = res.draw_info
  let equips = @equip.CharEquips::new()
  match weapon_item_id {
    Some(item_id) => {
      let weapon_path = "assets/Character/Weapon/\{@utils.stoi_left_pad0(item_id, 8)}.img.json"
      let weapon_node = parse_json_file(weapon_path)
      guard weapon_node is { "info": Object(info_map), .. } else {
        fail("Failed to parse weapon node for item \{item_id}")
      }
      let icon = match info_map.get("icon") {
        Some(v) => @json.from_json(v)
        None => fail("Missing icon for item \{item_id}")
      }
      let icon_raw = match info_map.get("iconRaw") {
        Some(v) => @json.from_json(v)
        None => fail("Missing iconRaw for item \{item_id}")
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
      equips.add_equip(weapon_item, @slot.Id::WEAPON, draw_info)
    }
    None => ()
  }

  equips
}

///|
fn make_final_attack_test_ctx(
  equips : @equip.CharEquips,
  trigger_count : Ref[Int],
  randomizer : @random.Rand,
  skill_level : Int,
  skill_data : @skill.SkillData?,
) -> PassiveContext {
  PassiveContext::{
    randomizer,
    get_character_equips_fn: fn(_ : Int) -> @equip.CharEquips? { Some(equips) },
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
test "sword_fa_fighter_triggers_with_sword_1h" {
  @local_loader.install_resource_env_for_test()
  let equips = make_test_equips(Some(1302000))
  let trigger_count = Ref(0)
  let passive = SwordFaFighterPassive::default()
  let skill_id = @skill.SkillId::SWORD_FA_FIGHTER.int_value()
  let skill_data = Some(@skill.SkillData::load(skill_id))
  let ctx = make_final_attack_test_ctx(
    equips,
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
  let equips = make_test_equips(Some(1312001))
  let trigger_count = Ref(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    equips,
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
  let equips = make_test_equips(Some(1402000))
  let trigger_count = Ref(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    equips,
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
  let trigger_count = Ref(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    @equip.CharEquips::default(),
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
  let equips = make_test_equips(Some(1302000))
  let trigger_count = Ref(0)
  let passive = SwordFaFighterPassive::default()
  let ctx = make_final_attack_test_ctx(
    equips,
    trigger_count,
    @random.Rand::chacha8(seed=b"12345678901234567890123456789012"),
    1,
    None,
  )
  passive.on_hit(ctx, make_hit_event(@combat_system.HitSource::Passive(99999)))
  assert_eq(trigger_count.val, 0)
}
