#!/usr/bin/env sh

print_output="$1"

cond_print() {
  if [ "$print_output" ]; then
    echo "$1"
  fi
}

# print_result $program $filename $out
print_result() {
  if [ "$?" -ne "0" ]; then
    if grep -f fine-messages <(echo "$3") >/dev/null; then
      # echo "Skipping test $2 because it has a fine message"
      true
    else
      echo "$1 FAILED ON: $2"
      cond_print "$3"
    fi
  else
    # echo "$1 passed on $2"
    true
  fi
}

contains() {
  grep "$1" <(echo "$2") >/dev/null
}

test_in_wasmtime() {
  if contains "gc\|tail-call" "$2"; then
    return
  fi
  features=`echo "$2" | tr ' ' ','`
  out=`wasmtime wast --wasm-features "$features" "$1" 2>&1`
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
  if grep "memory64\|wait-large.wast\|atomic" <(echo "$1") >/dev/null; then
    return
  fi
  features=`echo "$2" | sed 's/\b\(\w\|-\)\+\b/--enable-\0/g'`
  # unquoted to expand to separate arguments
  convert=`wast2json $features "$1" -o /tmp/wizard.json 2>&1`
  # TODO: Use a wast2json with more support, or find a better way to run wasts
  # (How does Ben do it?)
  if [ "$?" -ne "0" ]; then
    cond_print "conversion failed:\n$convert"
    return
  fi
  out=`spectest-interp $features /tmp/wizard.json 2>&1`
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

features() {
  fts=""
  if contains "multi-memory" "$1"; then
    fts="$fts multi-memory"
  fi
  if contains "memory64" "$1"; then
    fts="$fts memory64"
  fi
  if contains "threads\|atomics" "$1"; then
    fts="$fts threads"
  fi
  if contains "ext:gc" "$1"; then
    fts="$fts gc"
  fi
  if contains "tail-call" "$1"; then
    fts="$fts tail-call"
  fi
  if [ -z "$fts" ] && contains "ext:" "$1"; then
    fts="other"
  fi
  echo $fts
}

test_file() {
  if ! grep module "$1" >/dev/null; then
    cond_print "Skipping seemingly empty test $1"
    return
  fi
  if grep "missing-" <(echo "$1") >/dev/null; then
    cond_print "Skipping wasmtime feature flag test"
    return
  fi
  if grep component-model <(echo "$1") >/dev/null; then
    return
  fi
  if grep "$1" uninteresting >/dev/null; then
    cond_print "Skipping known uninteresting test $1"
    return
  fi
  fts=`features "$1"`
  test_in_wasmtime "$1" "$fts"
  test_in_reference_interpreter "$1"
  test_in_wizard "$1" "$fts"
  test_in_v8 "$1"
  test_in_spidermonkey "$1"
}

if [ -z "$1" ]; then
  for F in `find . -name '*.wast'`; do
    test_file "$F"
  done
elif [ "$1" = "run" ]; then
  test_file "$2"
elif [ "$1" = "p" ]; then
  shift
  for F in `find . -name '*.wast'`; do
    test_file "$F"
  done
else
  echo "Don't understand arguments"
fi

# Most JSC tests are essentially written in JS or irretrievably wrapped in
# JS. It might make sense to just make the JS vendors run those

# We can also run wasm stuff just all .wasm files they should parse and
# validate and maybe _start
