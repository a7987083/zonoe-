#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_ROOT="${ZON_VENDOR_CACHE:-${TMPDIR:-/tmp}/zonoemenu-vendor-cache}"

SCL_REPO="https://github.com/dogo/SCLAlertView.git"
SCL_COMMIT="624dcb1e9f528121636062e38c7df9c3ec20d70b"
SCL_CACHE="$CACHE_ROOT/SCLAlertView-$SCL_COMMIT"
SCL_DEST="$ROOT/testmod/Bsphp/SCLAlertView"

fetch_git_commit() {
  local repo="$1"
  local commit="$2"
  local dest="$3"

  if [[ -d "$dest/.git" ]] && [[ "$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)" == "$commit" ]]; then
    return 0
  fi

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  git init -q "$dest"
  git -C "$dest" remote add origin "$repo"
  git -C "$dest" fetch -q --depth=1 origin "$commit"
  git -C "$dest" checkout -q --detach FETCH_HEAD

  local resolved
  resolved="$(git -C "$dest" rev-parse HEAD)"
  if [[ "$resolved" != "$commit" ]]; then
    echo "vendor commit mismatch: expected $commit, got $resolved" >&2
    exit 1
  fi
}

materialize_sclalertview() {
  fetch_git_commit "$SCL_REPO" "$SCL_COMMIT" "$SCL_CACHE"

  rm -rf "$SCL_DEST"
  mkdir -p "$SCL_DEST"
  cp -R "$SCL_CACHE/SCLAlertView/." "$SCL_DEST/"

  local required=(
    SCLAlertView.h SCLAlertView.m
    SCLAlertViewResponder.h SCLAlertViewResponder.m
    SCLAlertViewStyleKit.h SCLAlertViewStyleKit.m
    SCLButton.h SCLButton.m SCLMacros.h
    SCLSwitchView.h SCLSwitchView.m
    SCLTextView.h SCLTextView.m
    SCLTimerDisplay.h SCLTimerDisplay.m
    'UIImage+ImageEffects.h' 'UIImage+ImageEffects.m'
  )

  local file
  for file in "${required[@]}"; do
    if [[ ! -s "$SCL_DEST/$file" ]]; then
      echo "missing pinned SCLAlertView file: $file" >&2
      exit 1
    fi
  done

  echo "SCLAlertView pinned at $SCL_COMMIT"
}

materialize_sclalertview
