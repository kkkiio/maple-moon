///|
pub(all) struct JobData {
  icon : @graphics.Texture
  skill_ids : Array[Int]
  name : String
}

///|
pub async fn JobData::load(id : Int) -> JobData {
  let strid = @utils.stoi_left_pad0(id, 3)
  let src = get_skill_loader().load_res_async([strid + ".img"])
  let strsrc = get_string_loader().load_res_async(["Skill.img", strid]) catch {
    _ => @resource.NxNode::from_test_value(Json::null())
  }
  let name = strsrc["bookName"].get_string() catch { _ => "" }
  JobData::new(src, name)
}

///|
pub fn JobData::new(src : @resource.NxNode, name : String) -> JobData {
  let icon = src["info"]["icon"] |> @graphics.Texture::from_resource
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

///|
using @resource {get_skill_loader, get_string_loader}
