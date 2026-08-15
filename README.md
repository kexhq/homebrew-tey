# Homebrew Tey

Homebrew tap for [Tey](https://github.com/kexhq/kex), the package and toolchain
manager for Kex.

It installs **Tey and no Kex**. Tey manages Kex versions itself — installing,
selecting and updating them under its own home — and a `kex` installed by brew
next to one installed by tey is two compilers under two managers, which drift
apart the first time either is upgraded. So a compiler arrives through tey:

```sh
brew tap kexhq/tey
brew install kexhq/tey/tey

tey kex install
export PATH="${TEY_HOME:-$HOME/.local/share/tey}/bin:$PATH"
```

Until the first tagged stable release the formula has no `url` to install from,
and that command will tell you so. Build the current development version
instead — that path compiles a Kex too (Tey is written in Kex), keeps it out of
PATH, and hands it to tey, which adopts it on first use:

```sh
brew install --HEAD kexhq/tey/tey
```

To rebuild after a new commit lands in the Kex repository, reinstall the
formula (`--HEAD` is only accepted by `brew install`):

```sh
brew reinstall --build-from-source kexhq/tey/tey
```

## What this tap tracks

The formula follows the **stable** Kex line only. Pre-releases — `-prealpha`,
`-alpha`, `-beta`, `-rc.N` — are published as GitHub releases and container
images, but never become what `brew install tey` hands you. Reach one through
Tey, which understands release channels:

```sh
tey kex list --pre
tey kex install --pre
tey kex install 0.4.0-rc.1
tey kex use 0.4.0-rc.1
```

`Formula/tey.rb` is updated by kexhq/kex's release workflow: publishing a
stable version opens a pull request here pointing the formula at that release's
`tey-<version>.tar.gz`. It rewrites only the region between the `# <<STABLE`
and `# STABLE>>` markers — edit around them, not inside them — and a release
reaches Homebrew when that pull request is merged.
