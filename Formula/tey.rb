class Tey < Formula
  desc "Package and Kex toolchain manager"
  homepage "https://github.com/kexhq/kex"

  # Everything between the STABLE markers — here and again below — is rewritten
  # by the `formula` job in kexhq/kex's .github/workflows/release.yml when a
  # STABLE version is tagged. Pre-releases (-prealpha/-alpha/-beta/-rc.N)
  # deliberately leave both alone, so `brew install tey` never moves anyone
  # onto an unfinished Kex; reach those with `tey kex install <version>`, which
  # understands channels.
  #
  # This one points at TEY, which is compiled to BEAM modules and therefore
  # architecture-independent: one small archive serves every platform. It sits
  # above `license` because that is the component order `brew audit` enforces.
  # <<STABLE-TEY
  url "https://github.com/kexhq/kex/releases/download/v0.3.1/tey-0.3.1.tar.gz"
  sha256 "b9c748aaf197efccb0ca72addcb1162cd3e5863b5483477abd2312850e4079e8"
  # STABLE-TEY>>

  license "MIT"

  head do
    url "https://github.com/kexhq/kex.git", branch: "main"
    # Only this path compiles anything: Tey is written in Kex, so building it
    # from a checkout means building Kex first.
    depends_on "cmake" => :build
  end

  # Tey needs only erlang. The rest are for the Kex it installs: a released
  # archive links them dynamically and was built against brew's copies, so
  # they have to be here before `tey kex install` can produce a working
  # compiler.
  depends_on "boost"
  depends_on "erlang"
  depends_on "gmp"
  depends_on "pcre2"
  depends_on "readline"
  # macOS hashes with CommonCrypto; only the Linux build links OpenSSL.
  depends_on "openssl@3" unless OS.mac?

  # The compiler for THIS machine, installed into the keg beside Tey.
  #
  # Homebrew is the only thing that may write during `brew install`, and only
  # inside its own keg: post-install runs with HOME redirected to a temp
  # directory and a sandbox that denies the real one, so "run `tey kex install`
  # as an install step" is not a thing that can work. Shipping the compiler as
  # a resource is — and it means `kex` runs the moment `brew install` finishes,
  # with nothing lazy and nothing to type.
  #
  # It is NOT on PATH and NOT a version Tey has to keep in step with: `kex` is
  # Tey's dispatcher, which prefers whatever Tey has selected and falls back to
  # this one only while Tey has selected nothing. `tey kex install` takes this
  # copy into the Tey home; every later version comes from Tey alone.
  # <<STABLE-KEX
  on_macos do
    resource "kex" do
      url "https://github.com/kexhq/kex/releases/download/v0.3.1/kex-0.3.1-macos-arm64.tar.gz"
      sha256 "af98ef799a48e996057a5f7be55ec460666f4deab00b9f5a3aa4d7b7e28a2122"
    end
  end

  on_linux do
    on_arm do
      resource "kex" do
        url "https://github.com/kexhq/kex/releases/download/v0.3.1/kex-0.3.1-linux-arm64.tar.gz"
        sha256 "c94f4a75e6e57885778f8df1f7a8a589ec8612361f36660a48534efea549b9ba"
      end
    end
    on_intel do
      resource "kex" do
        url "https://github.com/kexhq/kex/releases/download/v0.3.1/kex-0.3.1-linux-x86_64.tar.gz"
        sha256 "ba682d0c13ff09b0311a8fccd08ac43f1fc63e312b1f15ce90dfaaa0f7814a99"
      end
    end
  end
  # STABLE-KEX>>

  # The keg holds `bin/tey`, `bin/kex` — Tey's dispatcher, not a compiler — and
  # one Kex in libexec, off PATH. Tey owns every version from then on: a real
  # `kex` binary installed onto PATH by brew would be a second compiler under a
  # second manager, and the two would drift apart on the first upgrade of
  # either.
  def install
    if build.head?
      install_from_source
    else
      prefix.install Dir["*"]
      # One directory per archive, holding bin/kex and share/kex/{stdlib,
      # runtime,manifest}: the compiler cannot run without the stdlib sources,
      # and `-R`/`--compile` cannot without the runtime.
      resource("kex").stage do
        (libexec/"kex-toolchain").install Dir["*"]
      end
    end

    # The launcher prefers an `erl` baked in at install time over PATH, because
    # a .beam cannot be loaded by an older OTP than the one that compiled it
    # and PATH may well hold a different one. brew's erlang is the dependency
    # resolved for this keg, so it is the right one to name.
    inreplace bin/"tey", /^BAKED_ERL=.*$/, "BAKED_ERL='#{formula_opt_bin("erlang")}/erl'"
  end

  def caveats
    <<~EOS
      `kex` works now — it runs the compiler that came with this Tey. Tey owns
      every version from here:

        tey kex list [--pre]      tey kex install [<version>]
        tey kex use <version>     tey kex uninstall <version>

      `tey kex install` with nothing installed takes the bundled compiler into
      tey's own home, so it survives `brew uninstall`; with something installed
      it fetches the newest release.

      To enable automatic tey.lock conflict regeneration, run:
        tey setup merge-driver

      Kex is before 1.0.0: no backward compatibility is attempted between
      releases. Pin a version in your package.kex.
    EOS
  end

  test do
    assert_match(/^tey \d+\.\d+\.\d+/, shell_output("#{bin}/tey --version"))

    (testpath/"hello.kex").write <<~KEX
      main do
        IO.printLine([1, 2, 3].map { |n| n * 7 }.sum.to(String))
      end
    KEX

    # Nothing is installed or selected yet, so this exercises the whole point:
    # `kex` is runnable straight out of the keg, on both backends, which are
    # separate implementations that can break one at a time — the tree-walk
    # interpreter needs share/kex/stdlib, `-R` additionally needs
    # share/kex/runtime and a working erlc.
    assert_match(/^kex \d+\.\d+\.\d+/, shell_output("#{bin}/kex --version"))
    assert_equal "42\n", shell_output("#{bin}/kex #{testpath}/hello.kex")
    assert_equal "42\n", shell_output("#{bin}/kex -R #{testpath}/hello.kex")

    # And tey compiles with the same one.
    system bin/"tey", "init", "demo"
    assert_equal "Hello from demo!\n", shell_output("cd demo && #{bin}/tey run")

    # Taking it into the Tey home is offline and needs no network.
    system bin/"tey", "kex", "install"
    assert_path_exists testpath/".local/share/tey/current"
  end

  private

  # The bootstrap compiler is installed to libexec, DELIBERATELY off PATH, and
  # handed to tey as a seed: tey copies it into its own home on first use,
  # selects it, and from then on owns it like any version it installed itself.
  def install_from_source
    # The revision needs no help here: --HEAD is a git checkout, so CMake
    # reads it from the tree. Only the date has to be supplied.
    args = std_cmake_args + [
      "-DCMAKE_INSTALL_PREFIX=#{libexec}/kex-toolchain",
      "-DKEX_BUILD_DATE=#{Time.now.utc.strftime("%Y-%m-%d")}",
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build", "--parallel"
    # bin/kex plus share/kex/{stdlib,runtime,manifest}: the compiler cannot run
    # without the stdlib sources, and `-R`/`--compile` cannot without the
    # runtime. The whole tree is the unit tey adopts.
    system "cmake", "--install", "build"

    # Compiled by the compiler just built, never by whatever kex may already
    # be on PATH.
    system "make", "-C", "tey", "clean"
    system "make", "-C", "tey", "install", "PREFIX=#{prefix}",
                   "KEX=#{buildpath}/build/kex", "INSTALL_NONINTERACTIVE=1"
  end
end
