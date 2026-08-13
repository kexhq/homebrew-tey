# Homebrew Tey

Homebrew tap for [Tey and Kex](https://github.com/kexhq/kex).

Until the first tagged release, install the current development version with:

```sh
brew tap kexhq/tey
brew install --HEAD kexhq/tey/tey
```

To rebuild after a new commit lands in the Kex repository, reinstall the
formula (the `--HEAD` option is only used with `brew install`):

```sh
brew reinstall --build-from-source kexhq/tey/tey
```
