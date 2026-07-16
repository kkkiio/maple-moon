///|
priv struct QuestItemRequirement {
  id : Int
  count : Int
}

///|
priv struct QuestItemEffect {
  id : Int
  count : Int
  prop : Int?
}

///|
priv struct QuestDefinition {
  quest_id : Int
  phase0_npc : Int?
  phase0_lvmin : Int?
  phase0_required_quests : Map[Int, Int]
  phase0_items : Array[QuestItemRequirement]
  phase1_npc : Int?
  phase1_items : Array[QuestItemRequirement]
  act0_items : Array[QuestItemEffect]
  act1_items : Array[QuestItemEffect]
  act1_exp : Int
  act1_next_quest : Int?
}

///|
fn make_default_completed_quests() -> Map[Int, Int64] {
  { 2091: 0, 2089: 0 }
}

///|
fn LocalServer::set_default_quest_state(self : LocalServer) -> Unit {
  self.started_quests.clear()
  self.completed_quests = make_default_completed_quests()
}

///|
fn LocalServer::init_quest_runtime(self : LocalServer) -> Unit {
  let raw = @res.require_json("res://Quest/nx.json")
  self.quest_defs = parse_quest_definitions(raw)
}

///|
fn parse_quest_definitions(raw : Json) -> Map[Int, QuestDefinition] {
  let defs : Map[Int, QuestDefinition] = Map([])
  guard raw
    is { "Check.img": Object(check_img), "Act.img": Object(act_img), .. } else {
    return defs
  }
  for quest_id_text, check_json in check_img {
    let quest_id = @string.parse_int(quest_id_text) catch { _ => continue }
    let act_json = act_img.get_or_default(quest_id_text, Json::null())
    let def = parse_quest_definition(quest_id, check_json, act_json)
    if def.phase0_npc is Some(_) || def.phase1_npc is Some(_) {
      defs.set(quest_id, def)
    }
  }
  defs
}

///|
fn parse_quest_definition(
  quest_id : Int,
  check_json : Json,
  act_json : Json,
) -> QuestDefinition {
  let mut phase0_npc : Int? = None
  let mut phase0_lvmin : Int? = None
  let phase0_required_quests : Map[Int, Int] = Map([])
  let phase0_items : Array[QuestItemRequirement] = []
  let mut phase1_npc : Int? = None
  let phase1_items : Array[QuestItemRequirement] = []
  if check_json is Object(check_map) {
    if check_map.get("0") is Some(phase0_json) {
      parse_phase_checks(
        phase0_json,
        fn(npc) { phase0_npc = Some(npc) },
        fn(lvmin) { phase0_lvmin = Some(lvmin) },
        phase0_required_quests,
        phase0_items,
      )
    }
    if check_map.get("1") is Some(phase1_json) {
      parse_phase_checks(
        phase1_json,
        fn(npc) { phase1_npc = Some(npc) },
        fn(_lvmin) {  },
        Map([]),
        phase1_items,
      )
    }
  }

  let act0_items : Array[QuestItemEffect] = []
  let act1_items : Array[QuestItemEffect] = []
  let mut act1_exp = 0
  let mut act1_next_quest : Int? = None
  if act_json is Object(act_map) {
    if act_map.get("0") is Some(phase0_act_json) {
      parse_phase_act(phase0_act_json, act0_items, fn(_exp) {  }, fn(_next) {  })
    }
    if act_map.get("1") is Some(phase1_act_json) {
      parse_phase_act(phase1_act_json, act1_items, fn(exp) { act1_exp = exp }, fn(
        next_quest,
      ) {
        act1_next_quest = Some(next_quest)
      })
    }
  }
  {
    quest_id,
    phase0_npc,
    phase0_lvmin,
    phase0_required_quests,
    phase0_items,
    phase1_npc,
    phase1_items,
    act0_items,
    act1_items,
    act1_exp,
    act1_next_quest,
  }
}

///|
fn parse_phase_checks(
  phase_json : Json,
  set_npc : (Int) -> Unit,
  set_lvmin : (Int) -> Unit,
  required_quests : Map[Int, Int],
  items : Array[QuestItemRequirement],
) -> Unit {
  guard phase_json is Object(phase_obj) else { return }
  if phase_obj.get("npc").bind(parse_int_json) is Some(npc_id) {
    set_npc(npc_id)
  }
  if phase_obj.get("lvmin").bind(parse_int_json) is Some(level_min) {
    set_lvmin(level_min)
  }
  if phase_obj.get("quest") is Some(Object(quest_obj)) {
    for _, quest_status_json in quest_obj {
      guard quest_status_json is Object(status_obj) else { continue }
      guard status_obj.get("id").bind(parse_int_json) is Some(id) else {
        continue
      }
      let state = status_obj.get("state").bind(parse_int_json).unwrap_or(0)
      required_quests.set(id, state)
    }
  }
  if phase_obj.get("item") is Some(Object(item_obj)) {
    for _, item_json in item_obj {
      guard item_json is Object(item_map) else { continue }
      guard item_map.get("id").bind(parse_int_json) is Some(id) else {
        continue
      }
      let count = item_map.get("count").bind(parse_int_json).unwrap_or(0)
      items.push({ id, count })
    }
  }
}

///|
fn parse_phase_act(
  phase_json : Json,
  items : Array[QuestItemEffect],
  set_exp : (Int) -> Unit,
  set_next_quest : (Int) -> Unit,
) -> Unit {
  guard phase_json is Object(phase_obj) else { return }
  if phase_obj.get("exp").bind(parse_int_json) is Some(exp) {
    set_exp(exp)
  }
  if phase_obj.get("nextQuest").bind(parse_int_json) is Some(next_quest) {
    set_next_quest(next_quest)
  }
  if phase_obj.get("item") is Some(Object(item_obj)) {
    for _, item_json in item_obj {
      guard item_json is Object(item_map) else { continue }
      guard item_map.get("id").bind(parse_int_json) is Some(id) else {
        continue
      }
      let count = item_map.get("count").bind(parse_int_json).unwrap_or(0)
      let prop = item_map.get("prop").bind(parse_int_json)
      items.push({ id, count, prop })
    }
  }
}

///|
fn parse_int_json(json : Json) -> Int? {
  match json {
    Number(v, ..) => Some(v.to_int())
    String(s) => Some(@string.parse_int(s)) catch { _ => None }
    _ => None
  }
}

///|
fn LocalServer::build_player_quest_log_info(
  self : LocalServer,
) -> @server_proto.PlayerQuestLogInfo {
  let started = []
  let completed = []
  for quest_id, progress in self.started_quests {
    started.push((quest_id, progress))
  }
  for quest_id, completion_time in self.completed_quests {
    completed.push((quest_id, completion_time))
  }
  { started, completed }
}

///|
fn LocalServer::on_quest_action(self : LocalServer, json : Json) -> Unit raise {
  let msg : QuestActionMessage = @json.from_json(json)
  @io_service.execute_background(fn() { self.handle_quest_action(msg) }, on_error=fn(
    err,
  ) {
    @log.error("failed to handle quest action", data={
      "error": err.to_string(),
    })
  })
}

///|
fn LocalServer::handle_quest_action(
  self : LocalServer,
  msg : QuestActionMessage,
) -> Unit {
  match msg {
    StartQuest(quest_id~, npc_id~) => self.handle_start_quest(quest_id, npc_id)
    CompleteQuest(quest_id~, npc_id~, ..) =>
      self.handle_complete_quest(quest_id, npc_id)
    ForfeitQuest(quest_id~) => self.handle_forfeit_quest(quest_id)
  }
}

///|
fn LocalServer::handle_start_quest(
  self : LocalServer,
  quest_id : Int,
  npc_id : Int,
) -> Unit {
  guard self.quest_defs.get(quest_id) is Some(def) else {
    @log.warn("local server start quest ignored: missing definition", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
    })
    return
  }
  if self.can_start_quest(def, npc_id) is Err(reason) {
    @log.warn("local server start quest rejected", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
      "reason": reason,
    })
    return
  }
  guard self.apply_quest_item_effects(def.act0_items) else {
    @log.warn("local server start quest failed to apply act0", data={
      "quest_id": quest_id,
    })
    return
  }
  self.started_quests.set(quest_id, "")
  self.send_server_message(
    @server_proto.UpdateQuestInfoMessage::QuestUpdate(quest_id~, npc_id~),
  )
  self.save_character_inventory_snapshot()
  self.save_character_quest_snapshot()
}

///|
fn LocalServer::handle_complete_quest(
  self : LocalServer,
  quest_id : Int,
  npc_id : Int,
) -> Unit {
  guard self.quest_defs.get(quest_id) is Some(def) else {
    @log.warn("local server complete quest ignored: missing definition", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
    })
    return
  }
  if self.can_complete_quest(def, npc_id) is Err(reason) {
    @log.warn("local server complete quest rejected", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
      "reason": reason,
    })
    return
  }
  guard self.apply_quest_item_effects(def.act1_items) else {
    @log.warn("local server complete quest failed to apply act1", data={
      "quest_id": quest_id,
    })
    return
  }
  self.started_quests.remove(quest_id) |> ignore
  self.completed_quests.set(quest_id, 0)
  let mut next_quest = 0
  if def.act1_next_quest is Some(candidate_next_quest) {
    if self.quest_defs.get(candidate_next_quest) is Some(next_def) &&
      self.can_start_quest(next_def, npc_id) is Ok(_) &&
      self.apply_quest_item_effects(next_def.act0_items) {
      self.started_quests.set(candidate_next_quest, "")
      next_quest = candidate_next_quest
      self.send_server_message(
        @server_proto.UpdateQuestInfoMessage::QuestUpdate(
          quest_id=candidate_next_quest,
          npc_id~,
        ),
      )
    }
  }
  self.send_server_message(
    @server_proto.UpdateQuestInfoMessage::QuestFinish(
      quest_id~,
      npc_id~,
      next_quest~,
    ),
  )
  if def.act1_exp > 0 {
    self.send_server_message(@server_proto.ShowStatusExpGainMessage::{
      white: false,
      gain: def.act1_exp,
      in_chat: false,
      bonus_event_exp: 0,
      third_monster_kill_event: 0,
      wedding_bonus: 0,
      quest_bonus_rate: None,
      party_bonus_multiplier: 0,
      party_bonus: 0,
      equip_bonus: 0,
      internet_cafe_bonus: 0,
      rainbow_week_bonus: 0,
    })
  }
  self.save_character_inventory_snapshot()
  self.save_character_quest_snapshot()
}

///|
fn LocalServer::handle_forfeit_quest(
  self : LocalServer,
  quest_id : Int,
) -> Unit {
  if !self.started_quests.contains(quest_id) {
    @log.warn("local server forfeit quest rejected", data={
      "quest_id": quest_id,
      "reason": "quest not started",
    })
    self.send_server_message(
      @server_proto.UpdateQuestInfoMessage::QuestError(quest_id~),
    )
    return
  }
  self.started_quests.remove(quest_id) |> ignore
  self.save_character_quest_snapshot()
  self.send_server_message(
    @server_proto.UpdateQuestInfoMessage::QuestExpire(quest_id~),
  )
}

///|
fn LocalServer::can_start_quest(
  self : LocalServer,
  def : QuestDefinition,
  npc_id : Int,
) -> Result[Unit, String] {
  if self.started_quests.contains(def.quest_id) {
    return Err("quest already started")
  }
  if self.completed_quests.contains(def.quest_id) {
    return Err("quest already completed")
  }
  if def.phase0_npc is Some(expected_npc) && expected_npc != npc_id {
    return Err("unexpected npc")
  }
  if def.phase0_lvmin is Some(lvmin) && self.player_level() < lvmin {
    return Err("level too low")
  }
  for quest_id, expected_state in def.phase0_required_quests {
    if !self.match_quest_state(quest_id, expected_state) {
      return Err("quest prerequisite not met")
    }
  }
  for req in def.phase0_items {
    if !self.match_item_requirement(req) {
      return Err("item requirement not met")
    }
  }
  Ok(())
}

///|
fn LocalServer::can_complete_quest(
  self : LocalServer,
  def : QuestDefinition,
  npc_id : Int,
) -> Result[Unit, String] {
  if !self.started_quests.contains(def.quest_id) {
    return Err("quest not started")
  }
  if def.phase1_npc is Some(expected_npc) && expected_npc != npc_id {
    return Err("unexpected completion npc")
  }
  for req in def.phase1_items {
    if !self.match_item_requirement(req) {
      return Err("item requirement not met")
    }
  }
  Ok(())
}

///|
fn LocalServer::match_quest_state(
  self : LocalServer,
  quest_id : Int,
  expected_state : Int,
) -> Bool {
  match expected_state {
    0 =>
      !self.started_quests.contains(quest_id) &&
      !self.completed_quests.contains(quest_id)
    1 => self.started_quests.contains(quest_id)
    2 => self.completed_quests.contains(quest_id)
    _ => true
  }
}

///|
fn LocalServer::match_item_requirement(
  self : LocalServer,
  req : QuestItemRequirement,
) -> Bool {
  let item_count = self.count_inventory_item(req.id)
  if req.count > 0 {
    item_count >= req.count
  } else {
    item_count == 0
  }
}

///|
fn LocalServer::player_level(_self : LocalServer) -> Int {
  50
}

///|
fn LocalServer::count_inventory_item(self : LocalServer, item_id : Int) -> Int {
  guard InventoryType::by_item_id(item_id) is Some(invtype) else { return 0 }
  guard self.player_items.get(invtype) is Some(tab_items) else { return 0 }
  let mut count = 0
  for _, entry in tab_items {
    match entry {
      InventoryItemEntry::Item(id~, count=stack_count, ..) if id == item_id =>
        count += stack_count
      InventoryItemEntry::Equip(id~, ..) if id == item_id => count += 1
      _ => ()
    }
  }
  count
}

///|
fn LocalServer::remove_item_from_inventory(
  self : LocalServer,
  item_id : Int,
  quantity : Int,
) -> Bool {
  if quantity <= 0 {
    return true
  }
  guard InventoryType::by_item_id(item_id) is Some(invtype) else {
    return false
  }
  guard self.player_items.get(invtype) is Some(tab_items) else { return false }
  if invtype == InventoryType::EQUIP {
    let slots = []
    for slot, entry in tab_items {
      if entry is InventoryItemEntry::Equip(id~, ..) && id == item_id {
        slots.push(slot)
      }
    }
    if slots.length() < quantity {
      return false
    }
    for i = 0; i < quantity; i = i + 1 {
      let slot = slots[i]
      tab_items.remove(slot) |> ignore
      self.send_modify_inventory([modify_remove(invtype, slot)], None)
    }
    return true
  }
  let stack_slots : Array[(Int, Int)] = []
  for slot, entry in tab_items {
    if entry is InventoryItemEntry::Item(id~, count=stack_count, ..) &&
      id == item_id {
      stack_slots.push((slot, stack_count))
    }
  }
  let mut remaining = quantity
  for it in stack_slots {
    if remaining <= 0 {
      break
    }
    let (slot, stack_count) = it
    let taken = @cmp.minimum(remaining, stack_count)
    let next_count = stack_count - taken
    if next_count > 0 {
      guard tab_items.get(slot)
        is Some(
          InventoryItemEntry::Item(
            id~,
            cash~,
            expire~,
            count=_,
            owner~,
            flag~,
            invtype~,
            slot~
          )
        ) else {
        continue
      }
      tab_items.set(
        slot,
        InventoryItemEntry::Item(
          id~,
          cash~,
          expire~,
          count=next_count,
          owner~,
          flag~,
          invtype~,
          slot~,
        ),
      )
      self.send_modify_inventory(
        [modify_change_count(invtype, slot, next_count)],
        None,
      )
    } else {
      tab_items.remove(slot) |> ignore
      self.send_modify_inventory([modify_remove(invtype, slot)], None)
    }
    remaining -= taken
  }
  remaining == 0
}

///|
fn LocalServer::apply_quest_item_effects(
  self : LocalServer,
  effects : Array[QuestItemEffect],
) -> Bool {
  for effect in effects {
    if effect.count < 0 && self.count_inventory_item(effect.id) < -effect.count {
      return false
    }
  }
  for effect in effects {
    if effect.count < 0 &&
      !self.remove_item_from_inventory(effect.id, -effect.count) {
      return false
    }
  }
  for effect in effects {
    if effect.count > 0 && effect.prop is None {
      if !self.add_item_to_inventory(effect.id, effect.count) {
        return false
      }
    }
  }
  let optionals : Array[QuestItemEffect] = []
  let mut total_weight = 0
  for effect in effects {
    if effect.count > 0 && effect.prop is Some(prop) && prop > 0 {
      optionals.push(effect)
      total_weight += prop
    }
  }
  if total_weight > 0 {
    let mut selected_weight = self.drop_rng.int(limit=total_weight)
    let mut selected : QuestItemEffect? = None
    for effect in optionals {
      guard effect.prop is Some(weight) else { continue }
      if selected_weight < weight {
        selected = Some(effect)
        break
      }
      selected_weight -= weight
    }
    if selected is Some(it) && !self.add_item_to_inventory(it.id, it.count) {
      return false
    }
  }
  true
}
