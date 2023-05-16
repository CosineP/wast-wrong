(module
  ;; NB this should use a shared memory when it's supported
  (memory 1)

  (func (export "32.load8u") (param i32) (result i32)
    local.get 0 i32.atomic.load8_u)
  (func (export "32.load32u") (param i32) (result i32)
    local.get 0 i32.atomic.load)
)

;; aligned loads
(assert_return (invoke "32.load8u" (i32.const 0)) (i32.const 0))
