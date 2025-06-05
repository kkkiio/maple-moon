///|
pub(all) struct JobData {
  icon : @graphics.Texture
  skill_ids : Array[Int]
  name : String
}

///|
pub fn JobData::load(
  id : Int,
  string_loader : @resource.SyncLoader
) -> @utils.Future[JobData] {
  let strid = @string_format.extend_id(id, 3)
  @skill.skill_loader()
  .load_res([strid + ".img"])
  .map(fn(src) { JobData::new(id, src, string_loader) })
}

///|
pub fn JobData::new(
  id : Int,
  src : @resource.NxNode,
  string_loader : @resource.SyncLoader
) -> JobData {
  let strid = @string_format.extend_id(id, 3)
  let strsrc = string_loader.load_res(["Skill.img", strid])
  let icon = src["info"]["icon"] |> @graphics.Texture::from_resource
  let name = strsrc["bookName"].get_string()
  let skills = Array::new()
  for sub in src["skill"] {
    let skill_id = @strconv.parse_int?(sub.name()).or(0)
    if skill_id == 0 {
      continue
    }
    skills.push(skill_id)
  }
  { icon, skill_ids: skills, name }
}
