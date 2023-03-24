#!/usr/bin/env sh

print_output=""

test_in_wasmtime() {
  if grep ext:gc <(echo "$1") >/dev/null; then
    return
  fi
  if grep tail-call <(echo "$1") >/dev/null; then
    return
  fi
  out=`wasmtime wast --wasm-features all "$1" 2>&1`
  if [ "$?" -ne "0" ]; then
    if grep "expected elements segment does not fit, got instantiation failed" <(echo $out) >/dev/null; then
      true
    else
      echo "WASMTIME FAILED ON: $1"
      if [ "$print_output" ]; then
        echo "$out"
      fi
    fi
  fi
}

test_in_reference_interpreter() {
  if grep "ext:" <(echo "$1") >/dev/null; then
    return
  fi
  out=`wasm "$1" 2>&1`
  if [ "$?" -ne "0" ]; then
    echo "REFERENCE INTERPRETER FAILED ON: $1"
    if [ "$print_output" ]; then
      echo "$out"
    fi
  fi
}

test_in_wizard() {
  wast2json "$1" -o /tmp/wizard.json 2>/dev/null >/dev/null
  # TODO: Use a wast2json with more support, or find a better way to run wasts
  # (How does Ben do it?)
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`spectest-interp /tmp/wizard.json 2>&1`
  if [ "$?" -ne "0" ]; then
    echo "WIZARD FAILED ON: $1"
    if [ "$print_output" ]; then
      echo "$out"
    fi
  fi
}

test_in_v8() {
  wasm -d -i "$1" -o /tmp/thenodetest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`node /tmp/thenodetest.js 2>&1`
  if [ "$?" -ne "0" ]; then
    echo "V8 FAILED ON: $1"
    if [ "$print_output" ]; then
      echo "$out"
    fi
  fi
}

test_in_spidermonkey() {
  wasm -d -i "$1" -o /tmp/thejstest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`js /tmp/thejstest.js 2>&1`
  if [ "$?" -ne "0" ]; then
    echo "SPIDERMONKEY FAILED ON: $1"
    if [ "$print_output" ]; then
      echo "$out"
    fi
  fi
}

for F in `find . -name '*.wast'`; do
  if ! grep module "$F" >/dev/null; then
    echo "Skipping seemingly empty test $F"
    continue
  fi
  if grep component-model <(echo "$F") >/dev/null; then
    continue
  fi
  if grep "$F" uninteresting >/dev/null; then
    echo "Skipping known uninteresting test $F"
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
