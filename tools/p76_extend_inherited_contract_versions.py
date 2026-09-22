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
    ROOT / 'Tests/p73_six_button_routing_cleanup_contract.py',
    ROOT / 'Tests/p74_local_files_coordinator_contract.py',
]

for path in FILES:
    text = path.read_text(encoding='utf-8')
    if 'v1_p76' in text:
        continue

    exact = "assert version == 'v1_p74', f'unexpected VERSION: {version}'"
    if exact in text:
        text = text.replace(
            exact,
            "assert version in {'v1_p74', 'v1_p76'}, f'unexpected VERSION: {version}'",
            1,
        )

    text = text.replace("'v1_p74'}", "'v1_p74', 'v1_p76'}")

    if 'v1_p76' not in text:
        raise SystemExit(f'could not extend P76 version guards: {path.relative_to(ROOT)}')
    path.write_text(text, encoding='utf-8')

print('P76 inherited contract version guards aligned successfully')
