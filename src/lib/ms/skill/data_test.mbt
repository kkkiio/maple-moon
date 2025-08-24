///|
test "parse all job' skills" {
  struct JobSkills {
    skill : Map[String, SkillNxResource]
  } derive(@json.FromJson)
  for job_id in ["000", "100", "110"] {
    let json : Json = @json.parse(
      @fs.read_file_to_string("assets/Skill/\{job_id}.img.json"),
    )
    let job_skills : JobSkills = @json.from_json(json)
    let _ = job_skills.skill

  }
}
