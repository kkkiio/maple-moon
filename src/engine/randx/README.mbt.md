# randx

`randx` 提供基于 `@random.Rand` 的随机工具函数，避免引入额外包装类型。

## API

- `next_bool(state)`
- `below(state, percent)`
- `above(state, percent)`
- `next_real(state, from?, to)`
- `next_int(state, from?, to)`
- `choose(state, items)`

## 示例

```moonbit nocheck
///|
let rng = @random.Rand::new()

///|
let lucky = @randx.below(rng, 0.1)

///|
let roll = @randx.next_int(rng, from=1, 7)
```
