# local_loader

`local_loader` provides local-filesystem resource loaders for integration tests.
It does not own MapleStory resource path rules. JSON path resolution is delegated
to `@resource.resolve_json_resource_path`; this package only reads the resolved
file path and then selects the resolved JSON node path.

## Usage

```moonbit nocheck
///|
test "install local resource environment" {
  @local_loader.install_resource_env_for_test()
  let loader = @resource.require_async_loader("item")
  let json = loader.load_resource(["Consume", "0206.img", "02060000"])
  ignore(json)
}
```

