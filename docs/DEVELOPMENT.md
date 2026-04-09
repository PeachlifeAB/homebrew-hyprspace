# Homebrew Tap Development Guide

Reference for adding formulas, building bottles, and releasing to `peachlifeab/tap`.

## Directory Layout

```
homebrew-tap/
  Formula/         # .rb formula files
  Casks/           # .rb cask files
  docs/            # this guide
  bin/repo-state   # baseline state script
```

The dev repo at `~/Developer/homebrew-tap` is separate from the installed tap at
`/opt/homebrew/Library/Taps/peachlifeab/homebrew-tap`. Editing a formula in the
dev repo does NOT affect `brew install` until you either:
- push to GitHub and run `brew update`, or
- copy the file: `cp Formula/foo.rb /opt/homebrew/Library/Taps/peachlifeab/homebrew-tap/Formula/foo.rb`

## Adding a New Python Formula

### 1. Upstream Requirements

Before writing the formula, ensure the upstream package is ready:

- **`_version.py` must be correct.** If using `setuptools-scm`, the generated
  `_version.py` in the tarball must match the tag. If it doesn't, fix it upstream
  and re-tag. `setuptools-scm` writes `_version.py` at build time from git tags,
  but GitHub release tarballs don't include `.git`, so the file must be committed.
- **Tag the release.** The formula `url` points to a GitHub tag tarball.

### 2. Identify All Dependencies

Map the full dependency tree. For each dep, note:

| Question | Why it matters |
|----------|---------------|
| Pure Python or C extensions? | C extensions compile from source (slow, may fail on newer macOS) |
| Build backend (setuptools, poetry-core, flit, etc.)? | Must be available offline during `brew install` |
| Available as a wheel on PyPI? | Wheels skip compilation entirely |
| macOS-only? (e.g., pyobjc) | May need platform-specific wheels |

### 3. Homebrew Network Sandbox

**Homebrew blocks all network access during the `install` phase.** This is the
single most important constraint. It means:

- `pip install` cannot download anything from PyPI
- `build_isolation: true` (pip default) creates an isolated venv and downloads
  build deps -- this **fails** in the sandbox
- Every dependency must be declared as a Homebrew resource or dependency

**Consequences:**

| Situation | Solution |
|-----------|----------|
| Package needs setuptools to build | Add `depends_on "python-setuptools" => :build` |
| Package needs poetry-core to build | Add a `resource "poetry-core"` block |
| Package needs flit-core to build | Add a `resource "flit-core"` block |
| Package uses `setuptools-scm` for versioning | Patch `pyproject.toml` to remove it and set a static version |
| `pip install` with `build_isolation: true` | Always use `build_isolation: false` instead |

### 4. Source Tarballs vs Pre-built Wheels

**Default to source tarballs** (`*.tar.gz` sdist from PyPI). They work on all
architectures and are the standard Homebrew pattern.

**Use pre-built wheels** (`*.whl`) only when source compilation fails. Known cases:

- **pyobjc 12.1 on macOS 15+**: `CGWindowListCreateImageFromArray` is marked
  `unavailable` (not just deprecated), and pyobjc builds with `-Werror`. The
  source build fails with a hard error. Use `cp313-cp313-macosx_10_13_universal2`
  wheels instead.

When using wheels, be aware:

- Platform-specific wheels (e.g., `cp313-cp313-macosx_*.whl`) are zip archives.
  Homebrew's `resource.stage` extracts zips, which breaks the wheel.
- Use `resource.cached_download` + symlink instead of `resource.stage`:

```ruby
r = resource("pyobjc-core")
r.fetch
whl_link = buildpath/r.downloader.basename
ln_s r.cached_download, whl_link
system python, "-m", "pip", "--python", venv_python, "install", "--no-deps", whl_link
```

- `cached_download` returns the raw file path in the Homebrew cache, which has a
  SHA256 prefix in the filename. `r.downloader.basename` gives the clean original
  filename. The symlink bridges the two.

### 5. Formula Template

```ruby
class MyPackage < Formula
  include Language::Python::Virtualenv

  desc "Short description"
  homepage "https://github.com/org/repo"
  url "https://github.com/org/repo/archive/refs/tags/X.Y.Z.tar.gz"
  sha256 "..."
  license "MIT"

  bottle do
    root_url "https://github.com/PeachlifeAB/homebrew-tap/releases/download/mypackage-X.Y.Z"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "..."
  end

  depends_on "python-setuptools" => :build  # if any dep uses setuptools
  depends_on :macos                         # if macOS-only
  depends_on "python@3.13"

  # List every runtime dependency as a resource.
  # Get URLs and sha256 from: curl -fsSL "https://pypi.org/pypi/PACKAGE/VERSION/json"
  resource "some-dep" do
    url "https://files.pythonhosted.org/packages/.../some-dep-1.0.tar.gz"
    sha256 "..."
  end

  def install
    # Patch out setuptools-scm if the upstream uses it
    inreplace "pyproject.toml" do |s|
      s.gsub! '"setuptools-scm>=8"', ""   # remove from requires list
      s.gsub! 'dynamic = ["version"]', "" # remove dynamic version
    end
    # Add static version
    inreplace "pyproject.toml", /^\[project\]\nname = "mypackage"\n/,
              "[project]\nname = \"mypackage\"\nversion = \"#{version}\"\n"
    ENV["SETUPTOOLS_SCM_PRETEND_VERSION"] = version.to_s

    venv = virtualenv_create(libexec, "python3.13")

    # Install resources then main package, all with build_isolation: false
    venv.pip_install resources, build_isolation: false
    venv.pip_install_and_link buildpath, build_isolation: false
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mycommand --version")
  end
end
```

Adjust for wheel resources and non-setuptools build backends as needed (see
lgtvctrl.rb for a complete example).

### 6. Getting PyPI Resource Info

```bash
# Get sdist URL and sha256 for a specific version
curl -fsSL "https://pypi.org/pypi/PACKAGE/VERSION/json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for u in d['urls']:
    if u['packagetype'] == 'sdist':
        print(f\"url: {u['url']}\")
        print(f\"sha256: {u['digests']['sha256']}\")
"

# Get wheel URL (for platform-specific packages)
curl -fsSL "https://pypi.org/pypi/PACKAGE/VERSION/json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for u in d['urls']:
    fn = u['filename']
    if 'cp313' in fn and fn.endswith('.whl') and 'cp313t' not in fn:
        print(f\"url: {u['url']}\")
        print(f\"sha256: {u['digests']['sha256']}\")
"

# Check what build backend a package uses
curl -fsSL "https://pypi.org/pypi/PACKAGE/VERSION/json" | python3 -c "
import json, sys, tarfile, io
d = json.load(sys.stdin)
for u in d['urls']:
    if u['packagetype'] == 'sdist':
        print(u['filename'])
" 
# Then download and inspect: tar xzf ... -O '*/pyproject.toml' | grep -A3 build-system
```

## Building and Releasing a Bottle

Bottles are pre-built binaries. Users pour them instantly instead of compiling
from source. **Always build and upload a bottle for every formula release.**

### Step 1: Build from Source

```bash
# Install from source (needs network for resource downloads during fetch phase)
brew install --build-bottle peachlifeab/tap/mypackage
```

This is the slow step (~3-10 min for packages with C extensions). Use `bgtail`
if it takes more than a minute:

```bash
bgtail brew install --build-bottle peachlifeab/tap/mypackage
```

### Step 2: Verify Before Bottling

```bash
# Check the binary works
mycommand --version

# Run the formula test
brew test peachlifeab/tap/mypackage
```

Do NOT proceed to bottling if either fails.

### Step 3: Create the Bottle

```bash
brew bottle --json peachlifeab/tap/mypackage
```

This produces a file like `mypackage--X.Y.Z.arm64_tahoe.bottle.tar.gz` and a
JSON file with the bottle metadata.

### Step 4: Upload to GitHub Releases

**Critical: filename must match what Homebrew expects.**

- Homebrew expects: `mypackage-X.Y.Z.ARCH.bottle.tar.gz` (single dash, no rebuild number)
- `brew bottle` produces: `mypackage--X.Y.Z.ARCH.bottle.N.tar.gz` (double dash, rebuild number)
- If the formula has no `rebuild` line, Homebrew expects no `.N.` in the filename

```bash
# Rename to match Homebrew's expected URL pattern (single dash, no rebuild number)
cp mypackage--X.Y.Z.arm64_tahoe.bottle.1.tar.gz \
   mypackage-X.Y.Z.arm64_tahoe.bottle.tar.gz

# Create a GitHub release and upload
gh release create mypackage-X.Y.Z \
  ./mypackage-X.Y.Z.arm64_tahoe.bottle.tar.gz \
  --repo PeachlifeAB/homebrew-tap \
  --title "mypackage X.Y.Z" \
  --notes "Bottle for mypackage X.Y.Z (arm64_tahoe)"
```

### Step 5: Add Bottle Block to Formula

```ruby
bottle do
  root_url "https://github.com/PeachlifeAB/homebrew-tap/releases/download/mypackage-X.Y.Z"
  sha256 cellar: :any_skip_relocation, arm64_tahoe: "SHA256_OF_BOTTLE"
end
```

Get the sha256: `shasum -a 256 mypackage-X.Y.Z.arm64_tahoe.bottle.tar.gz`

**Do NOT add `rebuild N`** unless you are rebuilding a bottle for the same
version (e.g., fixing the formula without bumping the version). If you do add
`rebuild N`, the filename must include `.N.` (e.g., `bottle.1.tar.gz`).

### Step 6: Push, Verify Clean Install

```bash
# Commit and push
git add Formula/mypackage.rb
git commit -m "mypackage X.Y.Z: add bottle (arm64_tahoe)"
git push origin main

# Verify as a user would
brew update
brew install peachlifeab/tap/mypackage
# Should say "Pouring mypackage-X.Y.Z.arm64_tahoe.bottle.tar.gz"

mycommand --version
brew test peachlifeab/tap/mypackage
```

### Step 7: Clean Up

```bash
# Remove local bottle files
rm -f mypackage--*.bottle.* mypackage-*.bottle.*
```

## Version Bump Checklist

When bumping a formula version:

1. Update upstream tag and ensure `_version.py` is correct
2. Update `url` and `sha256` in formula (new tag tarball hash)
3. Update resource versions and hashes if deps changed
4. Remove the old `bottle do` block (new version = new bottle)
5. `brew style Formula/mypackage.rb`
6. Build, test, bottle, upload, re-add bottle block (steps 1-7 above)
7. Delete the old GitHub release if desired

## Debugging Build Failures

### Check build logs

```bash
ls -lt ~/Library/Logs/Homebrew/mypackage/
cat ~/Library/Logs/Homebrew/mypackage/NN.python3.13.log
```

Steps are numbered: `01.virtualenv_create`, `02.python3.13` (first resource),
etc. The last log file is where the failure occurred.

### Common failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Request failed after 3 retries` / `operation timed out` | Network sandbox blocking PyPI | Add missing resource or use `build_isolation: false` |
| `No module named 'setuptools'` | build_isolation: false but no setuptools available | Add `depends_on "python-setuptools" => :build` |
| `No module named 'poetry.core'` | wakeonlan (or similar) needs poetry-core | Add `resource "poetry-core"` installed before other resources |
| `-Werror` with `unavailable` API | macOS SDK marks old API as unavailable | Use pre-built wheel instead of source tarball |
| `Could not locate Python interpreter` | Venv broken or path mismatch | Check `libexec/bin/python` symlink exists |
| `ERROR: Could not build wheels` | Missing build backend | Check `pyproject.toml` build-system.requires, add as resource |

### Testing without brew overhead

Test pip commands directly against a temp venv to isolate issues:

```bash
python3.13 -m venv --system-site-packages --without-pip /tmp/test-venv
python3.13 -m pip --python /tmp/test-venv/bin/python install --no-deps PACKAGE
rm -rf /tmp/test-venv
```

## Local Dev Workflow

When iterating on a formula before pushing:

```bash
# Edit in dev repo
vim Formula/mypackage.rb

# Style check
brew style Formula/mypackage.rb

# Copy to installed tap for testing
cp Formula/mypackage.rb /opt/homebrew/Library/Taps/peachlifeab/homebrew-tap/Formula/

# Uninstall + reinstall
brew uninstall mypackage
brew install peachlifeab/tap/mypackage

# Once working, commit from dev repo and push
git add Formula/mypackage.rb
git commit -m "description"
git push origin main
```
