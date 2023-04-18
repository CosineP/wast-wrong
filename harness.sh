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

# get a good reference interpreter for the given features
get_interp() {
  if contains "threads" "$1"; then
    echo "wasm-threads"
  else
    echo "wasm"
  fi
}

test_in_wasmtime() {
  # unclear if extended-const are supported
  # relaxed simd is only partially supported
  if contains "gc\|tail-call\|extended-const\|annotations\|relaxed-simd" "$2"; then
    return
  fi
  features=`echo "$2" | tr ' ' ','`
  out=`wasmtime wast --wasm-features "$features" "$1" 2>&1`
  print_result WASMTIME "$1" "$out"
}

test_in_reference_interpreter() {
  if contains "gc\|multi-memory\|memory64\|extended-const\|annotations\|relaxed-simd" "$2"; then
    return
  fi
  interpreter=`get_interp "$2"`
  sed 's/\b\([sg]\)et_local\b/local.\1et/g' <"$1" >/tmp/interp.wast
  out=`$interpreter /tmp/interp.wast 2>&1`
  print_result "REFERENCE INTERPRETER" "$1" "$out"
}

test_in_wizard() {
  if grep "memory64\|wait-large.wast\|atomic\|extended-const" <(echo "$1") >/dev/null; then
    return
  fi
  # These ones are just because of wast2json and therefore should be fixed
  if contains "relaxed-simd" "$2"; then
    return
  fi
  # depends on not supporting relaxed-simd, so should be fixed when above is fixed
  features=`echo "$2" | sed 's/simd//g' | sed 's/  / /g' | sed 's/\b\(\w\|-\)\+\b/--enable-\0/g'`
  sed 's/\b\([sg]\)et_local\b/local.\1et/g' <"$1" >/tmp/wizard.wast
  # unquoted to expand to separate arguments
  convert=`wast2json $features /tmp/wizard.wast -o /tmp/wizard.json 2>&1`
  # TODO: Use a wast2json with more support, or find a better way to run wasts
  # (How does Ben do it?)
  if [ "$?" -ne "0" ]; then
    cond_print "WARNING: conversion produced error on $1:\n$convert"
    return
  fi
  out=`spectest-interp $features /tmp/wizard.json 2>&1`
  print_result WIZARD "$1" "$out"
}

test_in_v8() {
  if contains "multi-memory" "$2"; then
    return
  fi
  interpreter=`get_interp "$2"`
  $interpreter -d -i "$1" -o /tmp/thenodetest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  out=`node --experimental-wasm-return_call /tmp/thenodetest.js 2>&1`
  print_result V8 "$1" "$out"
}

test_in_spidermonkey() {
  if contains "tail-call\|multi-memory" "$2"; then
    return
  fi
  interpreter=`get_interp "$2"`
  $interpreter -d -i "$1" -o /tmp/thejstest.js 2>/dev/null >/dev/null
  # TODO: Use a reference interpreter with more support, or find a better way to run wasts
  if [ "$?" -ne "0" ]; then
    return
  fi
  # simd, threads enabled by default
  features=`echo "$2" | sed 's/simd\|threads//g' | sed 's/  \+/ /g' | sed 's/\b\(\w\|-\)\+\b/--wasm-\0/g'`
  # deliberate unquote
  out=`js $features /tmp/thejstest.js 2>&1`
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
  if contains "extended-const" "$1"; then
    fts="$fts extended-const"
  fi
  if contains "annotations" "$1"; then
    fts="$fts annotations"
  fi
  # Note that this means relaxed-simd => simd, which is okay!
  if contains "simd" "$1"; then
    fts="$fts simd"
  fi
  if contains "relaxed-simd" "$1"; then
    fts="$fts relaxed-simd"
  fi
  if [ -z "$fts" ] && contains "ext:\|proposals" "$1"; then
    echo "HARNESS WARNING: $1 proposal, but unparsed" 1>&2
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
  # We assume everyone passes the spec test suite. If not, something's wrong (with our harness i hope!)
  # We also exclude our minified tests that we keep in the same directory (oops)
  if grep 'spec_testsuite\|\./testsuite\|\./minified' <(echo "$1") >/dev/null; then
    return
  fi
  if grep "$1" uninteresting >/dev/null; then
    cond_print "Skipping known uninteresting test $1"
    return
  fi
  fts=`features "$1"`
  test_in_wasmtime "$1" "$fts"
  test_in_reference_interpreter "$1" "$fts"
  test_in_wizard "$1" "$fts"
  test_in_v8 "$1" "$fts"
  test_in_spidermonkey "$1" "$fts"
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
elif [ "$1" = "smoke" ]; then
  # Run the spec test suite and if anything fails something's gone horribly wrong
  # Note, something HAS gone horribly wrong, many times
  for F in `find testsuite -name '*.wast'`; do
    test_file "$F"
  done
else
  echo "Don't understand arguments"
fi

# Most JSC tests are essentially written in JS or irretrievably wrapped in
# JS. It might make sense to just make the JS vendors run those

# We can also run wasm stuff just all .wasm files they should parse and
# validate and maybe _start
