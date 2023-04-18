(module
  (memory 1 1)
  (func (export "cmpxchg") (result i64)
    (i64.store (i32.const 0) (i64.const 0xf0f0f0f0f0f0f0f0))
    (drop (i64.atomic.rmw8.cmpxchg_u
      (i32.const 0)
      (i64.const 0xf0f0f0f0f0f0f0f0)
      (i64.const 0x0000000000000011)))
    (i64.atomic.load (i32.const 0))))
(assert_return (invoke "cmpxchg") (i64.const 0xf0f0f0f0f0f0f0f0))
