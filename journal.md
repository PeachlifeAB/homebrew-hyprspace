# Debug Journal: 404 errors downloading GitHub release tarballs

**Reported**: 2026-04-07
**Symptom**: `brew install sive lgtvctrl` fails with 404 on source tarball downloads.
**Real-path reproduction**: `brew fetch sive lgtvctrl`
**Failing seam**: Formula source URLs pointed at nonexistent GitHub tag archives.
**Primary evidence**: curl 404 on `v0.1.0` and `v0.6.4` tag URLs; 200 on corrected URLs.
**Last failed assumption**: Remote tags existed with `v` prefix.
**Code red**: Off
**Current owner path**: `bin/repo-state`, `brew fetch`, `brew install --build-from-source`, `brew test`, `brew audit`
**Current verification target**: `brew update && brew upgrade sive lgtvctrl` exits 0.

---

## Entry 1

**Timestamp**: 2026-04-07 08:09
**Phase**: Patch

### Hypothesis

Both formula failures caused by wrong/nonexistent source URLs: `sive` used `v0.1.0` tag (not pushed to remote), `lgtvctrl` pointed at old `v0.6.4` URL which never existed on the 0.1.0-era project.

### Experiment or reconnaissance

- curl'd all candidate URLs; checked GitHub tags API for both repos.
- Ran `git ls-remote --tags origin` and `git tag --points-at HEAD` in both local repos.

### Observation

- `sive`: remote tags API returns `[]`; only commit archive resolves (200). SHA256: `55a15976cfeb2f47b592af3c3a79d69611a5a3db0b6bff3e2470a0e6039d1b3b`.
- `lgtvctrl`: remote tag `0.1.0` exists and resolves (200). SHA256: `748fc418e617ecfc1c32ceac6ff15affeae88128c5b64365575b3de5c27408f0`.

### Conclusion

Confirmed. Patched `sive.rb` to commit archive + explicit `version "0.1.0"`. Patched `lgtvctrl.rb` to `0.1.0` tag URL with correct SHA256.

### Next action

Commit, push, run `brew update && brew upgrade sive lgtvctrl`.
