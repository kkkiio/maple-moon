///|
async test "resolve reference requires preload" {
  @markup_text.clear_reference_data()
  let mut raised = false
  ignore(
    @markup_text.resolve_npc_name("1002001"[:]) catch {
      _ => {
        raised = true
        ""
      }
    },
  )
  inspect(raised, content="true")
}

///|
async test "resolve reference after preload" {
  @resource.register_async_loader(
    "string",
    @local_loader.make_local_string_loader(),
  )
  @markup_text.clear_reference_data()
  @markup_text.preload_reference_data()

  inspect(@markup_text.is_reference_data_ready(), content="true")
  inspect(@markup_text.resolve_npc_name("1012101"[:]), content="Maya")
  inspect(@markup_text.resolve_mob_name("2220100"[:]), content="Blue Mushroom")
  inspect(@markup_text.resolve_map_name("105040300"[:]), content="Sleepywood")
  inspect(
    @markup_text.resolve_item_name("4031006"[:]),
    content="Weird Medicine",
  )
}

///|
async test "resolve reference invalid id raises" {
  @resource.register_async_loader(
    "string",
    @local_loader.make_local_string_loader(),
  )
  @markup_text.clear_reference_data()
  @markup_text.preload_reference_data()

  let mut raised = false
  ignore(
    @markup_text.resolve_item_name("-1"[:]) catch {
      _ => {
        raised = true
        ""
      }
    },
  )
  inspect(raised, content="true")
}
