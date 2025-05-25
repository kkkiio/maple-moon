///|
test "parse quest resource" {
  let quest_resource = @fs.read_file_to_string!(
    "/Users/xieziheng/projects/maple-moon/src/lib/ms/quest/nx.pretty.json",
  )
  let json = @json.parse!(quest_resource)
  let _ : QuestResource = @json.from_json!(json)

}
