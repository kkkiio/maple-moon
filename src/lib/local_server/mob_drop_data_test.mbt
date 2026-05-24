///|
test "MobDropDatabase::has_drops" {
  let tsv =
    #|id	dropperid	itemid	minimum_quantity	maximum_quantity	questid	chance
    #|1	100100	4000019	1	1	0	200000

  let db = MobDropDatabase::from_tsv(tsv)
  inspect(db.has_drops(100100), content="true")
  inspect(db.has_drops(999999), content="false")
}

///|
test "MobDropEntry::roll_quantity" {
  let entry : MobDropEntry = {
    dropperid: 100100,
    itemid: 0,
    minimum_quantity: 10,
    maximum_quantity: 20,
    questid: 0,
    chance: 100000,
  }

  // 多次随机，验证结果在范围内
  for i = 0; i < 100; i = i + 1 {
    let rand = @random.Rand::new()
    let qty = entry.roll_quantity(rand)
    assert_true(qty >= 10 && qty <= 20)
  }

  // 测试min=max的情况
  let entry_fixed : MobDropEntry = {
    dropperid: 100100,
    itemid: 0,
    minimum_quantity: 5,
    maximum_quantity: 5,
    questid: 0,
    chance: 100000,
  }
  let rand = @random.Rand::new()
  inspect(entry_fixed.roll_quantity(rand), content="5")
}

///|
test "MobDropEntry::roll_drop with 100% chance" {
  let entry : MobDropEntry = {
    dropperid: 100100,
    itemid: 4000019,
    minimum_quantity: 1,
    maximum_quantity: 1,
    questid: 0,
    chance: 1000000, // 100%掉落
  }

  // 100%概率应该总是掉落
  let rand = @random.Rand::new()
  for i = 0; i < 10; i = i + 1 {
    assert_true(entry.roll_drop(rand))
  }
}

///|
test "MobDropEntry::roll_drop with 0% chance" {
  let entry : MobDropEntry = {
    dropperid: 100100,
    itemid: 4000019,
    minimum_quantity: 1,
    maximum_quantity: 1,
    questid: 0,
    chance: 0, // 0%掉落
  }

  // 0%概率应该永不掉落
  let rand = @random.Rand::new()
  for i = 0; i < 10; i = i + 1 {
    assert_false(entry.roll_drop(rand))
  }
}

///|
test "MobDropDatabase::roll_drops" {
  let tsv =
    #|id	dropperid	itemid	minimum_quantity	maximum_quantity	questid	chance
    #|1	100100	4000019	1	1	0	1000000
    #|2	100100	2000000	1	1	0	1000000
    #|3	100100	0	10	10	0	1000000

  let db = MobDropDatabase::from_tsv(tsv)

  // 100%概率，应该所有都掉落
  let rand = @random.Rand::new()
  let drops = db.roll_drops(100100, rand)
  inspect(drops.length(), content="3")

  // 验证掉落内容
  let itemids = drops.map(fn(x) { x.0 })
  assert_true(itemids.contains(4000019))
  assert_true(itemids.contains(2000000))
  assert_true(itemids.contains(0)) // 金币
}

///|
test "MobDropDatabase::roll_drops gates quest drops by started quest ids" {
  let tsv =
    #|id	dropperid	itemid	minimum_quantity	maximum_quantity	questid	chance
    #|1	100100	4000019	1	1	0	1000000
    #|2	100100	4031164	1	1	2084	1000000

  let db = MobDropDatabase::from_tsv(tsv)

  let no_quest_rand = @random.Rand::new()
  let drops_without_quest = db.roll_drops(100100, no_quest_rand, active_quest_ids={})
  inspect(drops_without_quest.length(), content="1")
  inspect(drops_without_quest[0].0, content="4000019")

  let active_quests : Map[Int, Unit] = { 2084: () }
  let started_quest_rand = @random.Rand::new()
  let drops_with_quest = db.roll_drops(
    100100,
    started_quest_rand,
    active_quest_ids=active_quests,
  )
  inspect(drops_with_quest.length(), content="2")
  let dropped_item_ids = drops_with_quest.map(fn(it) { it.0 })
  assert_true(dropped_item_ids.contains(4000019))
  assert_true(dropped_item_ids.contains(4031164))
}

///|
/// 测试 calculate_mob_drops 纯函数 - 使用 assets/data/mob_drops.tsv 中真实的猪猪掉落配置
/// 使用固定随机种子，让结果可预测，用 inspect 输出具体掉落内容
/// 真实数据位置：assets/data/mob_drops.tsv (dropperid=1210100)
test "calculate_mob_drops for pig with real config" {
  let tsv_content : String = @fs.read_file_to_string(
    "assets/data/mob_drops.tsv",
  ) catch {
    err => fail("failed to read mob_drops.tsv: \{err}")
  }
  let drop_db = MobDropDatabase::from_tsv(tsv_content)

  // 验证数据库中猪猪的掉落配置有 28 个可能的物品
  let pig_drops = drop_db.get_drops(1210100)
  inspect(pig_drops.length(), content="28")

  // 使用固定种子创建 Rand，让测试结果可预测
  let rand = @random.Rand::chacha8(seed=b"12345678901234567890123456789012")

  // 调用纯函数计算掉落
  let (messages, next_oid) = calculate_mob_drops(
    1210100, // mob_id (猪猪)
    500, // mob_x
    300, // mob_y
    100000, // start_oid
    Some(drop_db),
    None, // 无全局掉落
    rand,
  )

  // 输出掉落结果，用于验证
  json_inspect(messages, content=[
    {
      "mode": 0,
      "oid": 100001,
      "meso": true,
      "item_id": 14,
      "owner": 0,
      "pickuptype": 0,
      "dropto": [520, 300],
      "dropfrom": [520, 270],
      "player_drop": false,
    },
    {
      "mode": 0,
      "oid": 100002,
      "meso": false,
      "item_id": 4030012,
      "owner": 0,
      "pickuptype": 0,
      "dropto": [480, 300],
      "dropfrom": [480, 270],
      "player_drop": false,
    },
  ])
  json_inspect(next_oid, content=100002)
}
