(module
  (func (export "non_table_ref")
    (drop (ref.func 0))))
(invoke "non_table_ref")
