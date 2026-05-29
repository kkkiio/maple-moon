///|
pub(all) struct JobData {
  icon : @resource.NxTexture
  skill_ids : Array[Int]
  name : String
}

///|
pub fn JobData::load(id : Int) -> JobData {
  let strid = @utils.stoi_left_pad0(id, 3)
  let src = @resource.require_json("assets/Skill/" + strid + ".img.json")
  let name = match
    @resource.json_navigate("assets/String/Skill.img.json", [strid]) {
    { "bookName": String(name), .. } => name
    _ => ""
  }
  JobData::new(src, name)
}

///|
pub fn JobData::new(src : Json, name : String) -> JobData {
  let icon : @resource.NxTexture = try! @json.from_json(
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
      _ => {}
    }) {
    let skill_id = @string.parse_int(subname) catch { _ => 0 }
    if skill_id == 0 {
      continue
    }
    skills.push(skill_id)
  }
  { icon, skill_ids: skills, name }
}
