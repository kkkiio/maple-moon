///|
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
  available_skills : Map[Int, @skill.SkillData]
  watchers : Array[SkillBookWatcher]
  randomizer : @utils.Randomizer
}

///|
pub fn SkillBook::load(
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService,
  job : @job.Job,
  watchers : Array[SkillBookWatcher]
) -> @utils.Future[SkillBook] {
  job
  .get_all_subjobs()
  .flat_map(fn(it) { it.skill_ids.iter() })
  .map(fn(skill_id) {
    io_service.submit(fn() { @skill.SkillData::load(string_loader, skill_id) })
  })
  .collect()
  |> @utils.Future::all_of()
  |> _.map(fn(it) {
    let available_skills = Map::new()
    for skill_data in it {
      let skill_data = skill_data.unwrap() // TODO: handle error
      available_skills.set(skill_data.id, skill_data)
    }
    SkillBook::new(available_skills, watchers, @utils.Randomizer::new())
  })
}

///|
pub fn SkillBook::new(
  available_skills : Map[Int, @skill.SkillData],
  watchers : Array[SkillBookWatcher],
  randomizer : @utils.Randomizer
) -> SkillBook {
  { skill_entries: Map::new(), available_skills, watchers, randomizer }
}

///|
priv struct SkillEntry {
  level : Int
  master_level : Int
}

///|
pub impl @player.SkillBook for SkillBook with get_level(
  self : SkillBook,
  id : Int
) -> Int {
  self.skill_entries.get(id).map_or(0, fn(entry) -> Int { entry.level })
}

///|
pub fn collect_required(
  self : SkillBook,
  id : Int
) -> @immut/hashmap.T[Int, Int] {
  self.available_skills
  .get(id)
  .map_or(@immut/hashmap.new(), fn(skill_data) -> @immut/hashmap.T[Int, Int] {
    skill_data.req_skills
  })
}

///|
pub fn get_masterlevel(self : SkillBook, id : Int) -> Int {
  let iter = self.skill_entries.get(id)
  match iter {
    Some(entry) => entry.master_level
    None => 0
  }
}

///|
pub impl @player.SkillBook for SkillBook with set_skill(
  self : SkillBook,
  id : Int,
  level : Int,
  master_level : Int,
  _expiration : Int
) -> Unit {
  self.skill_entries.set(id, { level, master_level })
  self.watchers.retain(fn(listener) {
    listener({
      kind: "level",
      data_event: None,
      level_event: Some({ skill_id: id, level, available_sp: 0 }), // TODO: handle available_sp
    })
  })
}

///|
pub fn SkillBook::on_attack_event(
  self : SkillBook,
  event : @combat_impl2.AttackEvent,
  combat : @combat_impl2.Combat,
  player : @player.Player
) -> Unit {
  // 追加攻击
  guard event.user_input && event.result.damage_lines.size() > 0 else { return }
  // TODO: avoid hardcode
  let skill_id = @skill.SkillId::SWORD_FA_FIGHTER.int_value()
  // TODO: check weapon type
  guard self.skill_entries.get(skill_id) is Some(entry) else { return }
  guard entry.level > 0 else { return }
  let skill_data = self.available_skills.get(skill_id)
  guard skill_data is Some(skill_data) else { return }
  let stats = skill_data.stats.get(entry.level)
  guard stats is Some(stats) else { return }
  let act_fut = combat.get_skill_move(skill_id)
  guard act_fut.poll() is Some(act) else { return }
  // try on each mob
  let mob_targets = event.result.damage_lines
    .keys()
    .filter(fn(_) { self.randomizer.below(stats.prop.to_double() / 100.0) })
    .to_array()
  if mob_targets.length() == 0 {
    return
  }
  let attack = act.make_attack(
    player.character,
    player.inventory,
    @combat_proto.AttackType::MAGIC, // TODO: check attack type
    false,
  )
  let result = {
    ..@combat_proto.AttackResult::new(attack),
    attacker: player.character.get_oid(),
  }
  combat.apply_attack_to_mobs(
    player.character,
    act,
    attack,
    mob_targets,
    result,
    false,
  )
}

///|
pub fn get_skill_data(self : SkillBook, id : Int) -> @skill.SkillData? {
  self.available_skills.get(id)
}

///|
pub typealias (SkillBookEvent) -> Bool as SkillBookWatcher

///|
pub fn increase_sp(mod : Module, skill_id : Int) -> Unit {
  mod.network.send_message({ skill_id, }, log_level=@log.Level::INFO)
}

///| Requests a skill level increase by spending SP
priv struct SpendSPPacket {
  skill_id : Int
} derive(Show)

///|
impl @net.OutMessage for SpendSPPacket with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::SPEND_SP)
  packet..write_time()..write_int(self.skill_id)
  packet
}

///|
fn check_required(skillbook : SkillBook, id : Int) -> Bool {
  let required = skillbook.collect_required(id)
  for req in required {
    let (req_skill_id, req_level) = req
    let req_skill_level = skillbook.get_level(req_skill_id)
    if req_skill_level < req_level {
      return false
    }
  }
  return true
}

// ///|
// fn is_upgradable(
//   skillbook : SkillBook,
//   skill_id : Int,
//   tab : Int,
//   beginner_sp : Int,
//   sp : Int
// ) -> Bool {
//   let joblevel = joblevel_by_tab(tab)
//   if joblevel == @job.Level::BEGINNER && beginner_sp <= 0 {
//     return false
//   }
//   if tab != 0 && sp <= 0 {
//     return false
//   }
//   let level = skillbook.get_level(skill_id)
//   let mut masterlevel = skillbook.get_masterlevel(skill_id)
//   if masterlevel == 0 {
//     masterlevel = skillbook.get_skill_data(skill_id).unwrap().master_level // TODO: handle error
//   }
//   if level >= masterlevel {
//     return false
//   }
//   if skill_id == @skill.SkillId::ANGEL_BLESSING.int_value() {
//     false
//   } else {
//     check_required(skillbook, skill_id)
//   }
// }

// let beginner_skills : FixedArray[@skill.SkillId] = [
//   @skill.SkillId::THREE_SNAILS,
//   @skill.SkillId::HEAL,
//   @skill.SkillId::FEATHER,
// ]

///|
test "parse skill desc" {
  let origin =
    #|[Master Level : 20]\nUse MP to attack an enemy twice.\nRequired Skill : #cAt least Level 1 on Energy Bolt#
  inspect(
    markup_to_html(origin),
    content=
      #|<span style="color: black">[Master Level : 20]</span><br/>
      #|<span style="color: black">Use MP to attack an enemy twice.</span><br/>
      #|<span style="color: black">Required Skill : </span><div style="display: list-item;">At least Level 1 on Energy Bolt</div>
    ,
  )
}

///|
pub fn markup_to_html(origin : String) -> String raise {
  let nodes = @markup_text.parse_markup(origin, tag_map)
  let html = @markup_text.to_html(
    nodes,
    { color: @struct.ColorName::BLACK, bold: false },
    @markup_text.color_map,
    { 'c': fn(_, v) { "<div style=\"display: list-item;\">\{v}</div>" } },
  )
  html
}

///|
let tag_map : Map[Char, @markup_text.MarkupType] = @markup_text.common_tags
  .iter()
  .concat([('c', @markup_text.MarkupType::Pair)].iter())
  |> Map::from_iter
