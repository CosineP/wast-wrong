# Wast Wrong?

> Migrating WebAssembly tests

## About

This is a class project for [Advanced Software
Engineering](https://neu-se.github.io/CS4910-7580-Spring-2023/) with Jon
Bell. A requirement was to share a link to the software, and i don't
know how else to host files besides GitHub :). But you can read [the
report](./project-writeup.pdf) i wrote about it.

## Dependencies

Install nix package manager. Run `nix-shell`.

Then, download the following software sources, with these names, from
hopefully-obvious sources (TODO: submodules).

```
wizard-engine
wasmtime
WebKit
testsuite # only if you want to smoke test
```

Then, install wasmtime v7.0.0. One way to do that is to run `git submodule
update --init; cargo build --release` and then add `$PWD/target/release`
to your PATH.

## Run the tests

```
$ ./harness.sh p
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
