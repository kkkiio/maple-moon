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
/// 从CSV字符串解析掉落数据库
///
/// # 参数
/// - `csv_content`: CSV格式的字符串内容，包含表头
///
/// # 格式
/// 表头: "id","dropperid","itemid","minimum_quantity","maximum_quantity","questid","chance"
/// - dropperid: 怪物ID
/// - itemid: 物品ID (0表示金币)
/// - minimum_quantity: 最小数量
/// - maximum_quantity: 最大数量
/// - questid: 关联任务ID (0表示无任务限制)
/// - chance: 掉落概率 (基数 1000000)
pub fn MobDropDatabase::from_csv(csv_content : String) -> MobDropDatabase {
  let drops : Map[Int, Array[MobDropEntry]] = Map::new()
  let lines = csv_content.split("\n").collect()

  // 跳过表头，从第二行开始解析
  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.is_empty() {
      continue
    }

    // 解析CSV行（处理引号）
    let fields = parse_csv_line(line.to_string())
    // 需要7个字段: id, dropperid, itemid, minimum_quantity, maximum_quantity, questid, chance
    if fields.length() < 7 {
      continue
    }

    // 跳过id字段(fields[0])，从dropperid开始解析
    let dropperid = @strconv.parse_int(strip_quotes(fields[1])) catch {
      _ => continue
    }
    let itemid = @strconv.parse_int(strip_quotes(fields[2])) catch {
      _ => continue
    }
    let min_qty = @strconv.parse_int(strip_quotes(fields[3])) catch {
      _ => continue
    }
    let max_qty = @strconv.parse_int(strip_quotes(fields[4])) catch {
      _ => continue
    }
    let questid = @strconv.parse_int(strip_quotes(fields[5])) catch {
      _ => continue
    }
    let chance = @strconv.parse_int(strip_quotes(fields[6])) catch {
      _ => continue
    }

    let entry : MobDropEntry = {
      dropperid,
      itemid,
      minimum_quantity: min_qty,
      maximum_quantity: max_qty,
      questid,
      chance,
    }

    // 按怪物ID分组存储
    match drops.get(dropperid) {
      Some(list) => list.push(entry)
      None => drops.set(dropperid, [entry])
    }
  }

  { drops, }
}

///|
/// 去除字符串两端的引号
fn strip_quotes(s : String) -> String {
  let s = s.trim().to_string()
  if s.length() >= 2 && s.has_prefix("\"") && s.has_suffix("\"") {
    return s[1:s.length() - 1].to_string() catch { _ => s }
  }
  s
}

///|
/// 解析CSV行，处理引号包裹的字段
fn parse_csv_line(line : String) -> Array[String] {
  let fields : Array[String] = []
  let mut current = StringBuilder::new()
  let mut in_quotes = false
  let chars = line.to_array()

  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '"' {
      if in_quotes && i + 1 < chars.length() && chars[i + 1] == '"' {
        // 转义的引号
        current.write_char('"')
        i = i + 1
      } else {
        in_quotes = not(in_quotes)
      }
    } else if c == ',' && not(in_quotes) {
      fields.push(current.to_string())
      current = StringBuilder::new()
    } else {
      current.write_char(c)
    }
    i = i + 1
  }
  fields.push(current.to_string())
  fields
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
    Some(list) => not(list.is_empty())
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
) -> Array[(Int, Int)] {
  // 返回 (itemid, quantity) 列表
  let result : Array[(Int, Int)] = []
  let entries = self.get_drops(dropperid)

  for entry in entries {
    // Local server 暂不支持 quest 条件判定，先过滤任务限定掉落（questid != 0）。
    if entry.questid != 0 {
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
) -> (Array[@maple_protocol.DropLootMessage], Int) {
  let messages : Array[@maple_protocol.DropLootMessage] = []
  let mut drop_index = 0
  let mut current_oid = start_oid
  let base_x = mob_x
  let base_y = mob_y

  // 1. 生成怪物特定掉落
  match drop_db {
    Some(db) => {
      let drops = db.roll_drops(mob_id, rand)
      for item in drops {
        drop_index += 1
        current_oid += 1
        let (item_id, quantity) = item
        let is_meso = item_id == 0
        let final_item_id = if is_meso { quantity } else { item_id }
        let drop_x = base_x + (drop_index % 2 * 40 - 20)
        messages.push(@maple_protocol.DropLootMessage::{
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
      let global_drops = db.roll_drops(-1, rand) // continent -1 表示全局
      for item in global_drops {
        drop_index += 1
        current_oid += 1
        let (item_id, quantity) = item
        let is_meso = item_id == 0
        let final_item_id = if is_meso { quantity } else { item_id }
        let drop_x = base_x + (drop_index % 2 * 40 - 20)
        messages.push(@maple_protocol.DropLootMessage::{
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
test "parse_csv_line basic" {
  let line = "1,100100,4000019,1,1,0,200000"
  let fields = parse_csv_line(line)
  inspect(fields.length(), content="7")
  inspect(fields[0], content="1")
  inspect(fields[1], content="100100")
  inspect(fields[2], content="4000019")
  inspect(fields[3], content="1")
  inspect(fields[4], content="1")
  inspect(fields[5], content="0")
  inspect(fields[6], content="200000")
}

///|
test "parse_csv_line with quoted fields" {
  let line = "\"1\",\"100100\",\"4000019\",\"1\",\"1\",\"0\",\"200000\""
  let fields = parse_csv_line(line)
  inspect(fields.length(), content="7")
  inspect(strip_quotes(fields[1]), content="100100")
  inspect(strip_quotes(fields[2]), content="4000019")
}

///|
test "strip_quotes" {
  inspect(strip_quotes("\"hello\""), content="hello")
  inspect(strip_quotes("hello"), content="hello")
  inspect(strip_quotes("\"100100\""), content="100100")
}
