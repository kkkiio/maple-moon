test "test npc talk text" {
  let template = "Take this ship and you'll head off to a bigger continent. For #e150 mesos#n, I'll take you to #bVictoria Island#k. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?"
  let result = @text_tmpl.format_text!(
    template,
    {
      variable_map: {
        "e": fn(v) { "<b>\{v}</b>" },
        "b": fn(v) { "<span style=\"color: blue;\">\{v}</span>" },
      },
    },
  )
  inspect!(result, content=
    #|Take this ship and you'll head off to a bigger continent. For <b>150 mesos</b>n, I'll take you to <span style="color: blue;">Victoria Island</span>k. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?
  )
}
