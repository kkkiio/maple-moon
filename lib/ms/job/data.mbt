pub struct JobData {
  icon : @graphics.Texture
  skills : Array[Int]
  name : String
}

pub fn JobData::load(id : Int) -> JobData {
  let strid = @string_format.extend_id(id, 3)
  let src = @skill.skill_loader().load_res([strid + ".img"])
  let strsrc = @resource.string_loader().load_res(["Skill.img", strid])
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
  { icon, skills, name }
}

let cache : Map[Int, JobData] = Map::new()

pub fn JobData::get(id : Int) -> JobData {
  cache.get_or_init(id, fn() { JobData::load(id) })
}
