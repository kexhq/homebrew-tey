# Homebrew Tey

Homebrew tap for [Tey](https://github.com/kexhq/kex), the package and toolchain
manager for Kex.

Installing it gives you a working `kex`, with nothing further to run:

```sh
brew tap kexhq/tey
brew install kexhq/tey/tey
kex --version
```

The keg puts two commands on PATH — `tey`, and `kex`, which is **Tey's
dispatcher rather than a compiler**. It runs whichever toolchain Tey has
selected, so there is only ever one `kex` command and Tey decides what it means.
A real compiler installed onto PATH by brew, next to the ones Tey installs,
would be two compilers under two managers, and they drift apart the first time
either is upgraded.

The compiler itself is downloaded into the keg's `libexec`, off PATH, and used
from there until you ask Tey to take it over:

```sh
tey kex install             # copies it into Tey's home; no network needed
tey kex list [--pre]        # released and installed versions
tey kex install <version>   # any published version
tey kex use <version>       # switch what `kex` runs
```

Until the first tagged stable release the formula has no `url` to install from,
and that command will tell you so. Build the current development version
instead — it compiles a Kex too (Tey is written in Kex) and puts it in the same
place:

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
stable version opens a pull request here pointing the formula at that release.
It fills two marked regions and nothing else — `# <<STABLE-TEY` with the Tey
archive, `# <<STABLE-KEX` with one `resource` per platform for the compiler —
so edit around those markers, not inside them. A release reaches Homebrew when
that pull request is merged.
