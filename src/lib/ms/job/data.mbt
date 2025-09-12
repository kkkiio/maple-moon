///|
pub(all) struct JobData {
  icon : @graphics.Texture
  skill_ids : Array[Int]
  name : String
}

///|
pub async fn JobData::load(id : Int) -> JobData raise {
  let strid = @utils.stoi_left_pad0(id, 3)
  let src = @skill.skill_loader().load_res_async([strid + ".img"])
  JobData::new(id, src)
}

///|
pub fn JobData::new(id : Int, src : @resource.NxNode) -> JobData {
  let strid = @utils.stoi_left_pad0(id, 3)
  let icon = src["info"]["icon"] |> @graphics.Texture::from_resource
  let name = skill_texts
    .as_object()
    .bind(_.get(strid))
    .bind(_.as_object())
    .bind(_.get("bookName"))
    .unwrap_or(Json::null())
    .as_string()
    .unwrap_or("")
  let skills = Array::new()
  for sub in src["skill"] {
    let skill_id = @strconv.parse_int(sub.name()) catch { _ => 0 }
    if skill_id == 0 {
      continue
    }
    skills.push(skill_id)
  }
  { icon, skill_ids: skills, name }
}
