///|
/// 怪物掉落项配置
/// 对应 Cosmic drop_data 表的一行记录
pub(all) struct MobDropEntry {
  dropperid : Int
  itemid : Int
  minimum_quantity : Int
  maximum_quantity : Int
  questid : Int
  chance : Int
}

///|
/// 怪物掉落数据库
/// 按怪物ID(dropperid)索引的掉落列表
struct MobDropDatabase {
  drops : Map[Int, Array[MobDropEntry]]
}

///|
/// 从TSV字符串解析掉落数据库
///
/// # 参数
/// - `tsv_content`: TSV格式的字符串内容，包含表头
///
/// # 格式
/// 表头: id<TAB>dropperid<TAB>itemid<TAB>minimum_quantity<TAB>maximum_quantity<TAB>questid<TAB>chance
/// - dropperid: 怪物ID
/// - itemid: 物品ID (0表示金币)
/// - minimum_quantity: 最小数量
/// - maximum_quantity: 最大数量
/// - questid: 关联任务ID (0表示无任务限制)
/// - chance: 掉落概率 (基数 1000000)
pub fn MobDropDatabase::from_tsv(tsv_content : String) -> MobDropDatabase {
  let drops : Map[Int, Array[MobDropEntry]] = {}
  let by_dropper = @drop_sheet.build_drop_row_map(tsv_content)
  for dropperid, rows in by_dropper {
    let entries : Array[MobDropEntry] = []
    for row in rows {
      entries.push({
        dropperid: row.dropperid,
        itemid: row.itemid,
        minimum_quantity: row.minimum_quantity,
        maximum_quantity: row.maximum_quantity,
        questid: row.questid,
        chance: row.chance,
      })
    }
    drops.set(dropperid, entries)
  }
  { drops, }
}

///|
/// 获取指定怪物的所有掉落项
pub fn MobDropDatabase::get_drops(
  self : MobDropDatabase,
  dropperid : Int,
) -> Array[MobDropEntry] {
  match self.drops.get(dropperid) {
    Some(list) => list.copy()
    None => []
  }
}

///|
/// 判断指定怪物是否有掉落配置
pub fn MobDropDatabase::has_drops(
  self : MobDropDatabase,
  dropperid : Int,
) -> Bool {
  match self.drops.get(dropperid) {
    Some(list) => !list.is_empty()
    None => false
  }
}

///|
/// 获取数据库中所有有掉落配置的怪物ID
pub fn MobDropDatabase::get_mob_ids(self : MobDropDatabase) -> Iter[Int] {
  self.drops.keys()
}

///|
/// 计算掉落数量（在minimum_quantity和maximum_quantity之间随机）
pub fn MobDropEntry::roll_quantity(
  self : MobDropEntry,
  rand : @random.Rand,
) -> Int {
  if self.minimum_quantity >= self.maximum_quantity {
    return self.minimum_quantity
  }
  let range = self.maximum_quantity - self.minimum_quantity + 1
  self.minimum_quantity + rand.int(limit=range)
}

///|
/// 判定是否掉落（概率判定）
/// chance 是基于 1000000 的概率值
/// 例如 chance=200000 表示 20% 的掉落概率
pub fn MobDropEntry::roll_drop(
  self : MobDropEntry,
  rand : @random.Rand,
) -> Bool {
  let roll = rand.int(limit=1000000)
  roll < self.chance
}

///|
/// 执行完整的掉落判定，返回实际掉落的物品列表
/// 每个掉落项独立判定概率
pub fn MobDropDatabase::roll_drops(
  self : MobDropDatabase,
  dropperid : Int,
  rand : @random.Rand,
  active_quest_ids? : Map[Int, Unit] = {},
) -> Array[(Int, Int)] {
  // 返回 (itemid, quantity) 列表
  let result : Array[(Int, Int)] = []
  let entries = self.get_drops(dropperid)

  for entry in entries {
    if entry.questid != 0 && !active_quest_ids.contains(entry.questid) {
      continue
    }
    if entry.roll_drop(rand) {
      let qty = entry.roll_quantity(rand)
      result.push((entry.itemid, qty))
    }
  }

  result
}

///|
/// 计算怪物掉落消息（纯函数，无副作用）
///
/// # 参数
/// - `mob_id`: 怪物ID
/// - `mob_x`, `mob_y`: 怪物位置
/// - `start_oid`: 起始 object_id
/// - `drop_db`: 怪物特定掉落数据库
/// - `global_drop_db`: 全局掉落数据库
/// - `rand`: 随机数生成器（用于测试时控制随机种子）
///
/// # 返回
/// - `(Array[DropLootMessage], Int)`: 掉落消息列表和下一个 object_id
pub fn calculate_mob_drops(
  mob_id : Int,
  mob_x : Int,
  mob_y : Int,
  start_oid : Int,
  drop_db : MobDropDatabase?,
  global_drop_db : MobDropDatabase?,
  rand : @random.Rand,
  active_quest_ids? : Map[Int, Unit] = {},
) -> (Array[@server_proto.DropLootMessage], Int) {
  let messages : Array[@server_proto.DropLootMessage] = []
  let mut drop_index = 0
  let mut current_oid = start_oid
  let base_x = mob_x
  let base_y = mob_y

  // 1. 生成怪物特定掉落
  match drop_db {
    Some(db) => {
      let drops = db.roll_drops(mob_id, rand, active_quest_ids~)
      for item in drops {
        drop_index += 1
        current_oid += 1
        let (item_id, quantity) = item
        let is_meso = item_id == 0
        let final_item_id = if is_meso { quantity } else { item_id }
        let drop_x = base_x + (drop_index % 2 * 40 - 20)
        messages.push(@server_proto.DropLootMessage::{
          mode: 0,
          oid: current_oid,
          meso: is_meso,
          item_id: final_item_id,
          owner: 0,
          pickuptype: 0,
          dropto: { x: drop_x, y: base_y },
          dropfrom: { x: drop_x, y: base_y - 30 },
          player_drop: false,
        })
      }
    }
    None => ()
  }

  // 2. 生成全局掉落
  match global_drop_db {
    Some(db) => {
      let global_drops = db.roll_drops(-1, rand, active_quest_ids~) // continent -1 表示全局
      for item in global_drops {
        drop_index += 1
        current_oid += 1
        let (item_id, quantity) = item
        let is_meso = item_id == 0
        let final_item_id = if is_meso { quantity } else { item_id }
        let drop_x = base_x + (drop_index % 2 * 40 - 20)
        messages.push(@server_proto.DropLootMessage::{
          mode: 0,
          oid: current_oid,
          meso: is_meso,
          item_id: final_item_id,
          owner: 0,
          pickuptype: 0,
          dropto: { x: drop_x, y: base_y },
          dropfrom: { x: drop_x, y: base_y - 30 },
          player_drop: false,
        })
      }
    }
    None => ()
  }

  (messages, current_oid)
}

///|
test "parse_tsv_rows basic" {
  let tsv = "id\tdropperid\titemid\tminimum_quantity\tmaximum_quantity\tquestid\tchance\n1\t100100\t4000019\t1\t1\t0\t200000\n"
  let rows = @drop_sheet.parse_drop_rows(tsv)
  inspect(rows.length(), content="1")
  inspect(rows[0].dropperid, content="100100")
  inspect(rows[0].itemid, content="4000019")
}
