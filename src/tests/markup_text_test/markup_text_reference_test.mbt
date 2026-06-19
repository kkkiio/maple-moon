///|
test "resolve reference requires preload" {
  @markup_text.clear_reference_data()
  debug_inspect(
    Ok(@markup_text.resolve_npc_name("1002001"[:])) catch {
      e => Err(e)
    },
    content=(
      #|Err(DataNotReady)
    ),
  )
}
