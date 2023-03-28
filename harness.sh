#!/usr/bin/env sh

print_output=""

# print_result $program $filename $out
print_result() {
  if [ "$?" -ne "0" ]; then
    if grep -f fine-messages <(echo "$3") >/dev/null; then
      # echo "Skipping test $2 because it has a fine message"
      true
    else
      echo "$1 FAILED ON: $2"
      if [ "$print_output" ]; then
        echo "$3"
      fi
    fi
  else
    # echo "$1 passed on $2"
    true
  fi
}

test_in_wasmtime() {
  if grep ext:gc <(echo "$1") >/dev/null; then
    return
  fi
  if grep tail-call <(echo "$1") >/dev/null; then
    return
  fi
  out=`wasmtime wast --wasm-features all "$1" 2>&1`
  print_result WASMTIME "$1" "$out"
}

test_in_reference_interpreter() {
  if grep "ext:\|multi-memory\|memory64" <(echo "$1") >/dev/null; then
    return
  fi
  interpreter="wasm"
  if grep "threads\|atomics" <(echo "$1") >/dev/null; then
    interpreter="wasm-threads"
  fi
  sed 's/\b\([sg]\)et_local\b/local.\1et/g' <"$1" >/tmp/interp.wast
  out=`$interpreter /tmp/interp.wast 2>&1`
  print_result "REFERENCE INTERPRETER" "$1" "$out"
}

test_in_wizard() {
  if grep "memory64" <(echo "$1") >/dev/null; then
    return
  fi
  wast2json --enable-all "$1" -o /tmp/wizard.json 2>/dev/null >/dev/null
  # TODO: Use a wast2json with more support, or find a better way to run wasts
  # (How does Ben do it?)
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`spectest-interp --enable-all /tmp/wizard.json 2>&1`
  print_result WIZARD "$1" "$out"
}

test_in_v8() {
  wasm -d -i "$1" -o /tmp/thenodetest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`node --experimental-wasm-return_call /tmp/thenodetest.js 2>&1`
  print_result V8 "$1" "$out"
}

test_in_spidermonkey() {
  if grep tail-call <(echo "$1") >/dev/null; then
    return
  fi
  wasm -d -i "$1" -o /tmp/thejstest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`js /tmp/thejstest.js 2>&1`
  print_result SPIDERMONKEY "$1" "$out"
}

for F in `find . -name '*.wast'`; do
  if ! grep module "$F" >/dev/null; then
    echo "Skipping seemingly empty test $F"
    continue
  fi
  if grep "missing-" <(echo "$F") >/dev/null; then
    echo "Skipping wasmtime feature flag test"
    continue
  fi
  if grep component-model <(echo "$F") >/dev/null; then
    continue
  fi
  if grep "$F" uninteresting >/dev/null; then
    # echo "Skipping known uninteresting test $F"
    continue
  fi
  test_in_wasmtime "$F"
  test_in_reference_interpreter "$F"
  test_in_wizard "$F"
  test_in_v8 "$F"
  test_in_spidermonkey "$F"
done

# Most JSC tests are essentially written in JS or irretrievably wrapped in
# JS. It might make sense to just make the JS vendors run those

# We can also run wasm stuff just all .wasm files they should parse and
# validate and maybe _start
