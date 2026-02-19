///|
/// 读取文件内容为字符串 (使用 Node.js fs)
extern "js" fn read_file_to_string(path : String) -> String =
  #| (path) => require('node:fs').readFileSync(path, 'utf-8')

///|
test "MobDropDatabase::from_csv with real Cosmic format" {
  let csv =
    #|"id","dropperid","itemid","minimum_quantity","maximum_quantity","questid","chance"
    #|1,100100,4000019,1,1,0,200000
    #|2,100100,2000000,1,1,0,10000
    #|3,100101,4000020,1,1,0,250000

  let db = MobDropDatabase::from_csv(csv)

  // 验证怪物ID列表
  let mob_ids = db.get_mob_ids().collect()
  inspect(mob_ids.length(), content="2")

  // 验证100100的掉落
  let drops_100100 = db.get_drops(100100)
  inspect(drops_100100.length(), content="2")
  inspect(drops_100100[0].dropperid, content="100100")
  inspect(drops_100100[0].itemid, content="4000019")
  inspect(drops_100100[0].minimum_quantity, content="1")
  inspect(drops_100100[0].maximum_quantity, content="1")
  inspect(drops_100100[0].questid, content="0")
  inspect(drops_100100[0].chance, content="200000")

  // 验证100101的掉落
  let drops_100101 = db.get_drops(100101)
  inspect(drops_100101.length(), content="1")
  inspect(drops_100101[0].itemid, content="4000020")

  // 验证不存在的怪物
  let drops_none = db.get_drops(999999)
  inspect(drops_none.length(), content="0")
}

///|
test "MobDropDatabase::has_drops" {
  let csv =
    #|"id","dropperid","itemid","minimum_quantity","maximum_quantity","questid","chance"
    #|1,100100,4000019,1,1,0,200000

  let db = MobDropDatabase::from_csv(csv)
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
  let csv =
    #|"id","dropperid","itemid","minimum_quantity","maximum_quantity","questid","chance"
    #|1,100100,4000019,1,1,0,1000000
    #|2,100100,2000000,1,1,0,1000000
    #|3,100100,0,10,10,0,1000000

  let db = MobDropDatabase::from_csv(csv)

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
test "parse csv with empty lines" {
  let csv =
    #|"id","dropperid","itemid","minimum_quantity","maximum_quantity","questid","chance"
    #|1,100100,4000019,1,1,0,200000
    #|
    #|2,100101,4000020,1,1,0,250000
    #|

  let db = MobDropDatabase::from_csv(csv)
  inspect(db.get_drops(100100).length(), content="1")
  inspect(db.get_drops(100101).length(), content="1")
}

///|
/// 测试 calculate_mob_drops 纯函数 - 使用 assets/data/mob_drops.csv 中真实的猪猪掉落配置
/// 使用固定随机种子，让结果可预测，用 inspect 输出具体掉落内容
/// 真实数据位置：assets/data/mob_drops.csv (dropperid=1210100)
test "calculate_mob_drops for pig with real config" {
  let csv_content : String = read_file_to_string("assets/data/mob_drops.csv")
  let drop_db = MobDropDatabase::from_csv(csv_content)

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
