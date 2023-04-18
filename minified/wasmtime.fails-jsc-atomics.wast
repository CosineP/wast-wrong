(module
  (memory 1 1 shared)
  (func (export "init") (param $value i64) (i64.store (i32.const 0) (local.get $value)))
  (func (export "i64.atomic.load") (param $addr i32) (result i64) (i64.atomic.load (local.get $addr)))
  (func (export "i64.atomic.rmw8.cmpxchg_u") (param $addr i32) (param $expected i64)  (param $value i64) (result i64) (i64.atomic.rmw8.cmpxchg_u (local.get $addr) (local.get $expected) (local.get $value)))
)
(invoke "init" (i64.const 0xf0f0f0f0f0f0f0f0))
(assert_return (invoke "i64.atomic.rmw8.cmpxchg_u" (i32.const 0) (i64.const 0xf0f0f0f0f0f0f0f0) (i64.const 0x0000000000000011)) (i64.const 0xf0))
(assert_return (invoke "i64.atomic.load" (i32.const 0)) (i64.const 0xf0f0f0f0f0f0f0f0))
