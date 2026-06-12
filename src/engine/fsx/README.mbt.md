# fsx

Node.js filesystem FFI helpers used by command-line tools.

Current APIs:

- `exists_sync(path)`
- `read_file_sync(path, "utf-8")`
- `write_file_sync(path, content)`
- `mkdir_sync(path)`
- `mkdir_sync_recursive(path)`

## 示例（Node 后端）

```moonbit nocheck
let out_dir = "target/tmp"
if !(@fsx.exists_sync(out_dir)) {
  @fsx.mkdir_sync_recursive(out_dir)
}

let p = "target/tmp/sample.txt"
@fsx.write_file_sync(p, "hello")
let text = @fsx.read_file_sync(p, "utf-8")
inspect(text, content="hello")
```
