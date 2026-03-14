///|
pub(all) struct JobData {
  icon : @resource.NxTexture
  skill_ids : Array[Int]
  name : String
}

///|
pub async fn JobData::load(id : Int) -> JobData {
  let strid = @utils.stoi_left_pad0(id, 3)
  let src = get_skill_loader().load_resource([strid + ".img"])
  let name = match get_string_loader().load_resource(["Skill.img", strid]) {
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
    let skill_id = @strconv.parse_int(subname) catch { _ => 0 }
    if skill_id == 0 {
      continue
    }
    skills.push(skill_id)
  }
  { icon, skill_ids: skills, name }
}

///|
using @resource {get_skill_loader, get_string_loader}
