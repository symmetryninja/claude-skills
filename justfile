# claude-skills: checks before publishing.

set shell := ["bash", "-euo", "pipefail", "-c"]

# scan, validate and test everything
default: check

check: scan validate test

# fail if anything that looks private is tracked or staged
scan:
    #!/usr/bin/env bash
    set -uo pipefail
    files=$(git ls-files --cached --others --exclude-standard)
    bad=0
    hit() { echo "SCAN: $1"; bad=1; }
    # generic secret and personal-data patterns, safe to publish
    patterns=(
      'gh[pousr]_[A-Za-z0-9]{20,}'           # GitHub tokens
      'sk-[A-Za-z0-9_-]{20,}'                # API keys
      'AKIA[0-9A-Z]{16}'                     # AWS keys
      '-----BEGIN [A-Z ]*PRIVATE KEY-----'   # private keys
      '/home/[a-z]'                          # local home paths
      '/Users/[A-Za-z]'
      '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'      # IPv4 addresses
      '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'   # email addresses
    )
    for p in "${patterns[@]}"; do
      m=$(grep -nEI -e "$p" $files 2>/dev/null | grep -v 'users.noreply.github.com' | grep -v '^justfile:' || true)
      [ -n "$m" ] && hit "pattern $p" && echo "$m"
    done
    # private terms (names, hosts, domains) live in a git-ignored local file, one per line
    if [ -f .scan-private-terms ]; then
      while IFS= read -r t; do
        [ -z "$t" ] && continue
        m=$(grep -nIi -F -e "$t" $files 2>/dev/null || true)
        [ -n "$m" ] && hit "private term (see .scan-private-terms)" && echo "$m"
      done < .scan-private-terms
    else
      echo "note: no .scan-private-terms file; only generic patterns checked"
    fi
    # images must have no metadata (camera, GPS, software)
    for f in $(git ls-files --cached --others --exclude-standard | grep -iE '\.(png|jpe?g)$' || true); do
      n=$(identify -verbose "$f" 2>/dev/null | grep -ciE 'exif:|gps|xmp' || true)
      [ "$n" -gt 0 ] && hit "image metadata in $f (run just strip-images)"
    done
    [ $bad = 0 ] && echo "scan clean"
    exit $bad

# strip metadata from every image in the repo
strip-images:
    find . -path ./.git -prune -o -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print -exec mogrify -strip {} \;

# validate the marketplace and each plugin
validate:
    claude plugin validate .
    for d in */.claude-plugin; do claude plugin validate "$(dirname "$d")"; done

# run each skill's tests (any <skill>/tests/run.sh)
test:
    for t in */tests/run.sh; do echo "== $t"; bash "$t"; done
