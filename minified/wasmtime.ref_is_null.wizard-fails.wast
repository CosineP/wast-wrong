(module
  (func (export "func_is_null_with_non_null_funcref") (result i32)
    (ref.is_null (ref.func 0))
  )
)
(assert_return (invoke "func_is_null_with_non_null_funcref") (i32.const 0))

