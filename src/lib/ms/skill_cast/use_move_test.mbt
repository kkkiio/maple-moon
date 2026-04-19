///|
using @server_proto {type StatsEntry}

///|
fn read_skill_sfx_until(
  reader : @event.EventReader[@skill_sfx.SkillSfxEvent],
  expected_count : Int,
) -> Array[@skill_sfx.SkillSfxEvent] {
  let events = @skill_sfx.skill_sfx_event_bus.read(reader)
  if events.length() >= expected_count {
    return events
  }
  for _ in 0..<240 {
    match @bullet.get_current_bullet_system() {
      Some(system) => system.update(timestep=@logic_fps.STEP_TIME_MS.to_int64())
      None => ()
    }
    for event in @skill_sfx.skill_sfx_event_bus.read(reader) {
      events.push(event)
    }
    if events.length() >= expected_count {
      return events
    }
  }
  events
}

///|
test "use_move_integration_test" {
  @skill_sfx.clear_events()
  let sfx_reader : @event.EventReader[@skill_sfx.SkillSfxEvent] = @event.EventReader::new()
  ignore(@skill_sfx.skill_sfx_event_bus.read(sfx_reader))
  // 1. Setup Global Combat
  let mobs : @monster.MapMobs = @monster.MapMobs::new()
  @bullet.set_current_bullet_system(Some(@bullet.BulletSystem::new()))
  let combat = @combat_system.Combat::new(mobs)
  @combat_system.set_combat(Some(combat))

  // 2. Setup Mob
  let json_path = "assets/Mob/1210102.img.json"
  let content = @fs.read_file_to_string(json_path)
  let nx_mob : @monster.NxMob = @json.from_json(@json.parse(content))
  let mob_random = @random.Rand::new()
  let mob = @monster.Mob::new(
    nx_mob,
    object_id=1,
    monster_id=1210102,
    0,
    4,
    0,
    true,
    { x: 50, y: 0 },
    randomizer=mob_random,
  )
  mobs.add_mob(mob)

  // 3. Setup Character & Mocks
  let entity = @entity.Entity::new()
  // Mock look (needs afterimage for regular attack range)
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
  let weapon_data = try! @weapon.WeaponData::from_item_data(weapon_item)
  let after_image_name = weapon_data.get_afterimage()
  let after_image_path = "assets/Character/Afterimage/\{after_image_name}.img.json"
  let after_image_node = @fs.read_file_to_string(after_image_path)
    |> @json.parse
  let after_images : @char_look.NxAfterImages = @json.from_json(
    after_image_node,
  )
  @char_look.set_after_images(after_image_name, after_images)
  look.add_equip(weapon_item, @slot.Id::WEAPON)
  let char_stats = @char_stats.CharStats::new(
    StatsEntry::default(),
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
  char_stats.set_stat(@maple_stat.Id::LEVEL, 10)
  char_stats.set_stat(@maple_stat.Id::STR, 100)
  char_stats.set_stat(@maple_stat.Id::DEX, 50)
  char_stats.init_totalstats()
  char_stats.set_total(@maple_stat.EquipStatId::WATK, 100)
  char_stats.close_totalstats()
  char_stats.set_total(@maple_stat.EquipStatId::ACC, 999)
  let character = @character.Character::new(
    entity,
    100, // oid
    look,
    "TestPlayer",
    get_skilllevel=fn(_) { 0 },
    char_stats,
  )
  character.set_position({ x: 0, y: 0 })
  character.set_facing_right(true)

  // 4. Implement CombatCharacter trait for a mock wrapper
  let cc = MockCombatCharacter::{
    character,
    stats: char_stats,
    inventory: @legacy_types.MockInventory::default(),
    skill_book: @legacy_types.MockSkillBook::default(),
  }

  // 5. Verify result
  // Since we don't have a real server assertion here, verify through hit event bus.
  let reader : @event.EventReader[@combat_system.HitEvent] = @event.EventReader::new()
  ignore(@combat_system.hit_event_bus.read(reader))
  let mut attach_damage : Int? = None
  assert_true(char_stats.get_total(@maple_stat.EquipStatId::ACC) >= 2)
  assert_true(char_stats.get_maxdamage() >= 1)

  // 6. Trigger use_move (0 is Regular Attack)
  @skill_cast.use_move(cc, 0)
  debug_inspect(@skill_sfx.skill_sfx_event_bus.read(sfx_reader), content="[]")
  let events = @combat_system.hit_event_bus.read(reader)
  for event in events {
    let mut total_damage = 0
    for _target_oid, damage_lines in event.result.damage_lines {
      for line in damage_lines {
        total_damage += line.0
      }
    }
    attach_damage = Some(total_damage)
  }
  match attach_damage {
    Some(total_damage) => assert_true(total_damage >= 1)
    None => assert_true(false)
  }
}

///|
async test "arrow_bomb_bow_should_use_cast_range_then_aoe_range" {
  @skill_sfx.clear_events()
  @resource.register_async_loader(
    "skill",
    @resource.AsyncLoader::new(
      "test_local_skill",
      loader=@local_loader.LocalDirResourceLoader::new("assets/Skill"),
    ),
  )
  @resource.register_async_loader(
    "string",
    @resource.AsyncLoader::new(
      "test_local_string",
      loader=@local_loader.LocalDirResourceLoader::new("assets/String"),
    ),
  )

  // 1) Setup combat and map mobs.
  let mobs : @monster.MapMobs = @monster.MapMobs::new()
  @bullet.set_current_bullet_system(Some(@bullet.BulletSystem::new()))
  let combat = @combat_system.Combat::new(mobs)
  @combat_system.set_combat(Some(combat))

  let mob_json = @fs.read_file_to_string("assets/Mob/1210102.img.json")
  let nx_mob : @monster.NxMob = @json.from_json(@json.parse(mob_json))
  let mob_random = @random.Rand::new()
  mobs.add_mob(
    @monster.Mob::new(
      nx_mob,
      object_id=101,
      monster_id=1210102,
      0,
      4,
      0,
      true,
      { x: 350, y: 0 }, // outside Arrow Bomb aoe(150) but inside regular bow cast range(400)
      randomizer=mob_random,
    ),
  )
  mobs.add_mob(
    @monster.Mob::new(
      nx_mob,
      object_id=102,
      monster_id=1210102,
      0,
      4,
      0,
      true,
      { x: 460, y: 0 }, // outside regular cast range, but inside aoe around primary target
      randomizer=mob_random,
    ),
  )

  // 2) Setup bow character and afterimages.
  let entity = @entity.Entity::new()
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
  let weapon_node = @fs.read_file_to_string(
      "assets/Character/Weapon/01452000.img.json",
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
    item_id: 1452000,
    price: 0,
    gender: 0,
    name: "TestBow",
    desc: "",
    category: "Weapon",
    valid: true,
    untradable: false,
    unique: false,
    unsellable: false,
    cash_item: false,
  }
  let weapon_data = try! @weapon.WeaponData::from_item_data(weapon_item)
  let after_image_name = weapon_data.get_afterimage()
  let after_image_path = "assets/Character/Afterimage/\{after_image_name}.img.json"
  let after_image_node = @fs.read_file_to_string(after_image_path)
    |> @json.parse
  let after_images : @char_look.NxAfterImages = @json.from_json(
    after_image_node,
  )
  @char_look.set_after_images(after_image_name, after_images)
  look.add_equip(weapon_item, @slot.Id::WEAPON)

  let skill_id = @skill.SkillId::ARROW_BOMB_BOW.int_value()
  let char_stats = @char_stats.CharStats::new(
    StatsEntry::default(),
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
  char_stats.set_stat(@maple_stat.Id::LEVEL, 30)
  char_stats.set_stat(@maple_stat.Id::STR, 60)
  char_stats.set_stat(@maple_stat.Id::DEX, 120)
  char_stats.init_totalstats()
  char_stats.set_total(@maple_stat.EquipStatId::WATK, 200)
  char_stats.close_totalstats()
  char_stats.set_total(@maple_stat.EquipStatId::ACC, 999)
  let character = @character.Character::new(
    entity,
    100,
    look,
    "ArrowBombTester",
    get_skilllevel=fn(sid) { if sid == skill_id { 1 } else { 0 } },
    char_stats,
  )
  character.set_position({ x: 0, y: 0 })
  character.set_facing_right(true)

  let cc = ArrowBombCombatCharacter::{
    character,
    stats: char_stats,
    inventory: ArrowBombInventory::default(),
    skill_book: ArrowBombSkillBook::default(),
  }
  let special_move = @skill_cast.load_skill_move(skill_id)
  @skill_cast.register_move(special_move)

  // 3) Scenario A/B: primary by cast range, splash by aoe range.
  let reader : @event.EventReader[@combat_system.HitEvent] = @event.EventReader::new()
  let sfx_reader : @event.EventReader[@skill_sfx.SkillSfxEvent] = @event.EventReader::new()
  ignore(@combat_system.hit_event_bus.read(reader))
  ignore(@skill_sfx.skill_sfx_event_bus.read(sfx_reader))
  @skill_cast.use_move(cc, skill_id)
  let sfx_events1 = read_skill_sfx_until(sfx_reader, 3)
  debug_inspect(sfx_events1.length(), content="3")
  debug_inspect(sfx_events1[0].skill_id(), content="3101005")
  debug_inspect(sfx_events1[0].stage(), content="Use")
  debug_inspect(sfx_events1[1].stage(), content="Hit")
  debug_inspect(sfx_events1[2].stage(), content="Hit")
  let events1 = @combat_system.hit_event_bus.read(reader)
  let hit_targets1 : Array[Int] = events1
    .iter()
    .flat_map(fn(event) { event.result.damage_lines.keys() })
    .collect()
  assert_true(hit_targets1.contains(101))
  assert_true(hit_targets1.contains(102))

  // 4) Scenario C: no primary target => no hit.
  character.set_position({ x: -1200, y: 0 })
  @skill_cast.use_move(cc, skill_id)
  let sfx_events2 = @skill_sfx.skill_sfx_event_bus.read(sfx_reader)
  debug_inspect(sfx_events2.length(), content="1")
  debug_inspect(sfx_events2[0].skill_id(), content="3101005")
  debug_inspect(sfx_events2[0].stage(), content="Use")
  let events2 = @combat_system.hit_event_bus.read(reader)
  let hit_targets2 : Array[Int] = events2
    .iter()
    .flat_map(fn(event) { event.result.damage_lines.keys() })
    .collect()
  assert_true(hit_targets2.is_empty())
}

///|
struct MockCombatCharacter {
  character : @character.Character
  stats : @char_stats.CharStats
  inventory : @legacy_types.MockInventory
  skill_book : @legacy_types.MockSkillBook
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with get_character(
  self,
) {
  self.character
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with get_stats(self) {
  self.stats
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with get_inventory(
  self,
) {
  self.inventory
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with get_skill_book(
  self,
) {
  self.skill_book
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with can_attack(
  _self,
) {
  true
}

///|
impl @combat_system.CombatCharacter for MockCombatCharacter with rush(_self, _x) {

}

///|
struct ArrowBombInventory {} derive(Default)

///|
impl @legacy_types.Inventory for ArrowBombInventory with recalc_stats(_, _) {

}

///|
impl @legacy_types.Inventory for ArrowBombInventory with get_stat(_, _) {
  0
}

///|
impl @legacy_types.Inventory for ArrowBombInventory with has_projectile(_) {
  true
}

///|
impl @legacy_types.Inventory for ArrowBombInventory with get_bulletid(_) {
  2060000
}

///|
impl @legacy_types.Inventory for ArrowBombInventory with get_bulletcount(_) {
  1000
}

///|
struct ArrowBombSkillBook {} derive(Default)

///|
impl @legacy_types.SkillBook for ArrowBombSkillBook with get_level(_, skill_id) {
  if skill_id == @skill.SkillId::ARROW_BOMB_BOW.int_value() {
    1
  } else {
    0
  }
}

///|
impl @legacy_types.SkillBook for ArrowBombSkillBook with set_skill(
  _,
  _,
  _,
  _,
  _,
) {

}

///|
struct ArrowBombCombatCharacter {
  character : @character.Character
  stats : @char_stats.CharStats
  inventory : ArrowBombInventory
  skill_book : ArrowBombSkillBook
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with get_character(
  self,
) {
  self.character
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with get_stats(
  self,
) {
  self.stats
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with get_inventory(
  self,
) {
  self.inventory
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with get_skill_book(
  self,
) {
  self.skill_book
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with can_attack(
  _,
) {
  true
}

///|
impl @combat_system.CombatCharacter for ArrowBombCombatCharacter with rush(_, _) {

}
