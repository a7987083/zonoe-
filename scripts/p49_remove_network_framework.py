#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / 'testmod.xcodeproj' / 'project.pbxproj'
text = p.read_text(errors='replace')
lines = text.splitlines(keepends=True)
matched = [ln for ln in lines if 'Network.framework' in ln]
if len(matched) != 7:
    raise SystemExit(f'expected exactly 7 Network.framework PBX lines, got {len(matched)}')
new_lines = [ln for ln in lines if 'Network.framework' not in ln]
new = ''.join(new_lines)
if 'Network.framework' in new:
    raise SystemExit('Network.framework residual remains in PBX')
p.write_text(new)
print('NETWORK_PBX_LINES_REMOVED=7')
