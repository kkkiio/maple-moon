///|
pub(all) struct JobData {
  icon : @res.NxTexture
  skill_ids : Array[Int]
  name : String
}

///|
pub fn JobData::load(id : Int) -> JobData {
  let strid = @utils.stoi_left_pad0(id, 3)
  let src = @res.require_json("res://Skill/" + strid + ".img.json")
  let name = match
    @res.require_json_node("res://String/Skill.img.json", [strid]) {
    { "bookName": String(name), .. } => name
    _ => ""
  }
  JobData(src, name)
}

///|
pub fn JobData::JobData(src : Json, name : String) -> JobData {
  let icon : @res.NxTexture = try! @json.from_json(
    match src {
      { "info": { "icon": icon, .. }, .. } => icon
      _ => Json::null()
    },
  )
  let skills = Array::new()
  // for sub in src["skill"] {
  for
    subname, _ in (match src {
      { "skill": Object(skill), .. } => skill
      _ => Map([])
    }) {
    let skill_id = @string.parse_int(subname) catch { _ => 0 }
    if skill_id == 0 {
      continue
    }
    skills.push(skill_id)
  }
  { icon, skill_ids: skills, name }
}
