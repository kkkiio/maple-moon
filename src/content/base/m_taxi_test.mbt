///|
test "mTaxi beginner trip charges discounted fare and warps" {
  let scripts = @base.npc_scripts()
  let script = scripts.require("mTaxi")
  let context : @content_runtime.NpcScriptContext = {
    npc_id: 1002004,
    job_id: 0,
    meso: 1000,
  }
  let introduction = (script.start)(context)
  assert_true(introduction.prompt is Some(Next(_)))
  let confirmation = (script.respond)(introduction.state, Continue, context)
  assert_true(confirmation.prompt is Some(YesNo(_)))
  let travel = (script.respond)(confirmation.state, Yes, context)
  assert_true(travel.finished)
  assert_eq(travel.commands.length(), 2)
  assert_true(travel.commands[0] is TakeMeso(1000))
  assert_true(travel.commands[1] is Warp(map_id=105070001, portal_id=0))
}

///|
test "mTaxi keeps the player in place when fare is insufficient" {
  let scripts = @base.npc_scripts()
  let script = scripts.require("mTaxi")
  let context : @content_runtime.NpcScriptContext = {
    npc_id: 1032005,
    job_id: 100,
    meso: 9999,
  }
  let introduction = (script.start)(context)
  let confirmation = (script.respond)(introduction.state, Continue, context)
  let rejected = (script.respond)(confirmation.state, Yes, context)
  assert_true(rejected.prompt is Some(Ok(_)))
  assert_true(rejected.commands.is_empty())
  assert_false(rejected.finished)
}
