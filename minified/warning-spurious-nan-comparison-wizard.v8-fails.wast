(module
  (func (export "nan") (param f32) (result f32)
    (f32.min (f32.const nan) (local.get 0))))
(assert_return (invoke "nan" (f32.const 42)) (f32.const nan))
