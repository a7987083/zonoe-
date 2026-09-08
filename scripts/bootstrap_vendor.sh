#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_files() {
  local base="$1"
  shift

  local file
  for file in "$@"; do
    if [[ ! -s "$base/$file" ]]; then
      echo "missing checked-in dependency: ${base#$ROOT/}/$file" >&2
      exit 1
    fi
  done
}

require_files "$ROOT/testmod/Bsphp/SCLAlertView" \
  SCLAlertView.h SCLAlertView.m \
  SCLAlertViewResponder.h SCLAlertViewResponder.m \
  SCLAlertViewStyleKit.h SCLAlertViewStyleKit.m \
  SCLButton.h SCLButton.m SCLMacros.h \
  SCLSwitchView.h SCLSwitchView.m \
  SCLTextView.h SCLTextView.m \
  SCLTimerDisplay.h SCLTimerDisplay.m \
  'UIImage+ImageEffects.h' 'UIImage+ImageEffects.m'

require_files "$ROOT/testmod/Bsphp/MBProgressHUD" \
  MBProgressHUD.h MBProgressHUD.m \
  'MBProgressHUD+NJ.h' 'MBProgressHUD+NJ.m'

require_files "$ROOT/testmod/Bsphp/AFNetworking" \
  AFHTTPSessionManager.h AFHTTPSessionManager.m \
  AFNetworkReachabilityManager.h AFNetworkReachabilityManager.m \
  AFNetworking.h \
  AFSecurityPolicy.h AFSecurityPolicy.m \
  AFURLRequestSerialization.h AFURLRequestSerialization.m \
  AFURLResponseSerialization.h AFURLResponseSerialization.m \
  AFURLSessionManager.h AFURLSessionManager.m

require_files "$ROOT/testmod/Bsphp" WX_NongShiFu123.h WX_NongShiFu123.mm

echo "checked-in legacy dependencies verified"
