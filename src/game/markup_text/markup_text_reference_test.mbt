///|
test "resolve reference requires preload" {
  @markup_text.clear_reference_data()
  try @markup_text.resolve_npc_name("1002001"[:]) catch {
    error =>
      debug_inspect(
        error,
        content=(
          #|DataNotReady
        ),
      )
  } noraise {
    _ => fail("expected DataNotReady")
  }
}
