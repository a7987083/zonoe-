#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / 'Tests/p65_backup_engine_contract.py',
    ROOT / 'Tests/p67_remote_download_contract.py',
    ROOT / 'Tests/p68_cloud_save_contract.py',
    ROOT / 'Tests/p69_save_transfer_coordinator_contract.py',
    ROOT / 'Tests/p70_backup_presentation_coordinator_contract.py',
    ROOT / 'Tests/p71_local_restore_coordinator_contract.py',
    ROOT / 'Tests/p72_reset_presentation_coordinator_contract.py',
]

for path in FILES:
    if not path.exists():
        raise SystemExit(f'missing inherited contract: {path.relative_to(ROOT)}')
    text = path.read_text(encoding='utf-8')

    if path.name == 'p72_reset_presentation_coordinator_contract.py':
        old = "assert version == 'v1_p72', f'unexpected VERSION: {version}'"
        new = "assert version in {'v1_p72', 'v1_p73'}, f'unexpected VERSION: {version}'"
        if old in text:
            text = text.replace(old, new, 1)
        elif new not in text:
            raise SystemExit(f'P72 version guard marker missing: {path}')
    else:
        old = "'v1_p72'}"
        new = "'v1_p72', 'v1_p73'}"
        if old in text:
            # A contract may have more than one version-dependent branch. Extend all of them.
            text = text.replace(old, new)
        elif 'v1_p73' not in text:
            raise SystemExit(f'expected inherited version-set tail missing: {path.relative_to(ROOT)}')

    path.write_text(text, encoding='utf-8')

print('P73 inherited contract version guards aligned successfully')
