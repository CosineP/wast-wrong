# "Wast" Wrong with WebAssembly?

> Migrating WebAssembly tests

## About

This is a class project for [Advanced Software
Engineering](https://neu-se.github.io/CS4910-7580-Spring-2023/) with Jon
Bell. You can look at [a poster](./wast-wrong-poster.svg) i made or read [a
report](./project-writeup.pdf) i wrote about it, including analysis of failures
found. Reporting and validating failures is ongoing work.

## Dependencies

Make sure to download this repository with submodules:

```
git clone --recurse-submodules git@github.com:CosineP/wast-wrong.git
```

I have a small patch to the wasmtime tests that prevents a few failures in
wasmtime.patch.

Install nix package manager. Run `nix-shell`. *Otherwise you will need to
manually install many packages, and i can't help you.*

Then, install wasmtime v7.0.0. One way to do that is to run `cd wasmtime &&
cargo build --release` and then add `$PWD/wasmtime/target/release` to your
PATH.

## Run the tests

```
$ ./harness.sh p # | grep FAILED for quiet output
```

## Are these all definitely bugs?

**No.** While I've put a lot of effort into making sure silly spurious failures
haven't crept in, it's not guaranteed that every failure is a bug. Reporting
these failures to maintainers will be the only way to ultimately determine
that.

## Are there known false positives?

Known false positives are in the file called `uninteresting`. They are
automatically excluded from the test harness. Note that 31 of these are the
same spurious failure over many instructions.

## Other things you can do with the harness

Runs each implementation on a single test:

```
$ ./harness.sh run ./my-test.wast
```

Run the harness on the spec testsuite to see many spurious failures:

```
$ ./harness.sh smoke
```
