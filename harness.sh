#!/usr/bin/env sh

test_in_wasmtime() {
  if grep ext:gc <(echo "$1") >/dev/null; then
    return
  fi
  if grep ext:tail-call <(echo "$1") >/dev/null; then
    return
  fi
  out=`wasmtime wast --wasm-features all "$1" 2>&1`
  if [ "$?" -ne "0" ]; then
    if grep "expected elements segment does not fit, got instantiation failed" <(echo $out) >/dev/null; then
      true
    else
      echo "WASMTIME FAILED ON: $1"
      echo "$out"
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
    echo "$out"
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
    echo "$out"
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
    echo "$out"
  fi
}

# wizard wast tests in wasmtime
for F in `find wizard-engine -name '*.wast'`; do
  if ! grep module "$F" >/dev/null; then
    echo "Skipping seemingly empty test $F"
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
done

# wasmtime tests in
