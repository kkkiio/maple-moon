# io_service

提供游戏线程上的任务提交与轮询辅助。

## 使用方式

`submit_background_task` 接受可能抛错的任务，并把执行结果包装成
`Future[Result[T, Error]]`。调用方应在 system 边界轮询 `Result`，并在 `Err` 分支记录
足够上下文后终止或恢复。

```moonbit nocheck
let loading = @io_service.submit_background_task(fn() {
  try! AppResources::load()
})

match loading.poll() {
  Some(Ok(resources)) => resources.install()
  Some(Err(err)) => abort("failed to load app resources: \{err}")
  None => ()
}
```

`execute_background` 用于 fire-and-forget 副作用任务；如果任务抛错，会调用 `on_error`。
