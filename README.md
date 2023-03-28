# Wast Wrong?

## Dependencies

If you use nix, run `nix-shell`. Otherwise, open shell.nix and read between the lines.

Then, download the following software sources, with these names, from hopefully obvious sources (TODO: submodules). (You don't need V8 for now, since they don't have any wast tests, and you should have downloaded a V8 binary in the previous step.)

```
wizard-engine
wasmtime
WebKit
```

## Run the tests

```
$ ./harness.sh
```

To see the output / messages of failures, add "yes" to print_output at the top of harness.sh

## Are there false positives

### ***YES***
