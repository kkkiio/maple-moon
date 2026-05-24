///|
struct Module {
  bullet_data : Map[Int, BulletData]
}

///|
pub let all_bullet_ids : Array[String] = [
  "02060003", "02060005", "02060006", "02061003", "02060004", "02061004", "02060000",
  "02060001", "02060002", "02061000", "02061001", "02061002", "02070000", "02070001",
  "02070002", "02070003", "02070004", "02070005", "02070006", "02070009", "02070010",
  "02070011", "02070012", "02070013", "02070007", "02070008", "02070015", "02070016",
  "02070018", "02330000", "02330001", "02330002", "02330003", "02330004", "02330005",
  "02330006", "02331000", "02332000",
]

///|
let module_ref : Ref[Module?] = Ref(None)

///|
pub fn Module::load() -> Module {
  let bullet_data = Map([])
  for id in all_bullet_ids {
    let data = BulletData::load(id)
    let int_id = (id.trim_start(chars="0").to_owned() |> @string.parse_int) catch {
      _ => abort("Invalid bullet id: \{id}")
    }
    bullet_data.set(int_id, data)
  }
  Module::new(bullet_data)
}

///|
pub fn Module::new(bullet_data : Map[Int, BulletData]) -> Module {
  { bullet_data, }
}

///|
pub fn Module::get_bullet_data(self : Module, id : Int) -> BulletData? {
  self.bullet_data.get(id)
}

///|
pub fn set_bullet_module(mod : Module) -> Unit {
  module_ref.val = Some(mod)
}

///|
pub fn get_bullet_module() -> Module {
  match module_ref.val {
    Some(mod) => mod
    None => @log.fatal("bullet module is not initialized")
  }
}

///|
pub fn get_bullet_data(id : Int) -> BulletData {
  match get_bullet_module().get_bullet_data(id) {
    Some(data) => data
    None => @log.fatal("bullet data missing", data={ "bullet_id": id })
  }
}
