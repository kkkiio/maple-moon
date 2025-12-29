///|
using @maple_protocol {type StatsEntry}

///|
test "use_move_integration_test" {
  // 1. Setup Global Combat
  let mobs : @monster.MapMobs = @monster.MapMobs::new()
  let bullet_module : @bullet.Module = @bullet.Module::new({})
  let combat = @combat_impl.Combat::new(
    @ui.NumberSet::default(),
    mobs,
    bullet_module,
  )
  @combat_impl.set_combat(Some(combat))

  // 2. Setup Mob
  let json_path = "assets/mob/1210102.img.json"
  let content = @fs.read_file_to_string(json_path)
  let nx_mob : @monster.NxMob = @json.from_json(@json.parse(content))
  let mob_random = @utils.Randomizer::new(
    state=@random.Rand::chacha8(seed=b"0123456789abcdef0123456789abcdef"),
  )
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
  mobs.get_mobs().add(mob)

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
  // Since we don't have a server listener here, we can check if the attack was applied to mobs.
  // Note: apply_attack_to_mobs normally sends a packet. 
  // We can listen to attack events.
  let mut attach_damage : Int? = None
  combat.listen_attack_events(fn(event) {
    let mut total_damage = 0
    for _target_oid, damage_lines in event.result.damage_lines {
      for line in damage_lines {
        total_damage += line.0
      }
    }
    attach_damage = Some(total_damage)
    true
  })
  assert_true(char_stats.get_total(@maple_stat.EquipStatId::ACC) >= 2)
  assert_true(char_stats.get_maxdamage() >= 1)

  // 6. Trigger use_move (0 is Regular Attack)
  @combat_impl.use_move(cc, 0)
  match attach_damage {
    Some(total_damage) => assert_true(total_damage >= 1)
    None => assert_true(false)
  }
}

///|
struct MockCombatCharacter {
  character : @character.Character
  stats : @char_stats.CharStats
  inventory : @legacy_types.MockInventory
  skill_book : @legacy_types.MockSkillBook
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with get_character(
  self,
) {
  self.character
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with get_stats(self) {
  self.stats
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with get_inventory(
  self,
) {
  self.inventory
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with get_skill_book(
  self,
) {
  self.skill_book
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with can_attack(_self) {
  true
}

///|
impl @combat_impl.CombatCharacter for MockCombatCharacter with rush(_self, _x) {

}
