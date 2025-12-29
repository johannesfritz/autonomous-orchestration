#!/usr/bin/env python3
"""
Pre-commit secrets scanner for Claude Code hooks.

Scans staged files for potential secrets before git operations.
Exit code 2 blocks the git operation in Claude Code.

Usage:
    python scan-secrets.py [file_paths...]

If no file paths provided, scans all staged files.
"""

import re
import sys
import subprocess
from pathlib import Path
from typing import NamedTuple


class SecretPattern(NamedTuple):
    """Pattern definition for secret detection."""
    name: str
    pattern: str
    severity: str  # critical, high, medium


# Secret patterns to detect
SECRET_PATTERNS = [
    # API Keys
    SecretPattern(
        "OpenAI API Key",
        r"sk-[a-zA-Z0-9]{20,}",
        "critical"
    ),
    SecretPattern(
        "Anthropic API Key",
        r"sk-ant-[a-zA-Z0-9\-_]{20,}",
        "critical"
    ),
    SecretPattern(
        "AWS Access Key ID",
        r"AKIA[0-9A-Z]{16}",
        "critical"
    ),
    SecretPattern(
        "AWS Secret Access Key",
        r"(?i)aws[_\-]?secret[_\-]?access[_\-]?key['\"]?\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{40})",
        "critical"
    ),
    SecretPattern(
        "Google API Key",
        r"AIza[0-9A-Za-z\-_]{35}",
        "critical"
    ),
    SecretPattern(
        "GitHub Token",
        r"gh[pousr]_[A-Za-z0-9_]{36,}",
        "critical"
    ),
    SecretPattern(
        "GitHub Personal Access Token (Classic)",
        r"ghp_[A-Za-z0-9]{36}",
        "critical"
    ),
    SecretPattern(
        "Stripe API Key",
        r"sk_live_[0-9a-zA-Z]{24,}",
        "critical"
    ),
    SecretPattern(
        "Stripe Test Key",
        r"sk_test_[0-9a-zA-Z]{24,}",
        "high"
    ),

    # Private Keys
    SecretPattern(
        "RSA Private Key",
        r"-----BEGIN RSA PRIVATE KEY-----",
        "critical"
    ),
    SecretPattern(
        "OpenSSH Private Key",
        r"-----BEGIN OPENSSH PRIVATE KEY-----",
        "critical"
    ),
    SecretPattern(
        "PGP Private Key",
        r"-----BEGIN PGP PRIVATE KEY BLOCK-----",
        "critical"
    ),
    SecretPattern(
        "EC Private Key",
        r"-----BEGIN EC PRIVATE KEY-----",
        "critical"
    ),

    # Passwords and Secrets
    SecretPattern(
        "Hardcoded Password",
        r"(?i)(password|passwd|pwd)['\"]?\s*[:=]\s*['\"]([^'\"]{8,})['\"]",
        "high"
    ),
    SecretPattern(
        "Hardcoded Secret",
        r"(?i)(secret|api[_\-]?key|auth[_\-]?token)['\"]?\s*[:=]\s*['\"]([^'\"]{8,})['\"]",
        "high"
    ),
    SecretPattern(
        "Database Connection String",
        r"(?i)(mongodb|postgres|mysql|redis):\/\/[^:]+:[^@]+@",
        "critical"
    ),

    # JWT and Tokens
    SecretPattern(
        "JWT Token",
        r"eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+",
        "high"
    ),
    SecretPattern(
        "Bearer Token",
        r"(?i)bearer\s+[a-zA-Z0-9\-_.~+/]+=*",
        "medium"
    ),

    # Generic high-entropy strings (potential secrets)
    SecretPattern(
        "High Entropy String (potential secret)",
        r"['\"][A-Za-z0-9+/]{40,}={0,2}['\"]",
        "medium"
    ),
]

# Files to skip (binary, generated, etc.)
SKIP_EXTENSIONS = {
    '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg',
    '.woff', '.woff2', '.ttf', '.eot',
    '.pdf', '.zip', '.tar', '.gz',
    '.pyc', '.pyo', '.so', '.dll', '.exe',
    '.min.js', '.min.css', '.map',
}

# Directories to skip
SKIP_DIRS = {
    'node_modules', 'venv', '.venv', '__pycache__',
    '.git', '.svn', 'dist', 'build', 'coverage',
}

# Files that commonly contain example/fake secrets (reduce noise)
ALLOW_LIST_FILES = {
    '.env.example', '.env.sample', '.env.template',
    'example.env', 'sample.env',
}


def get_staged_files() -> list[str]:
    """Get list of files staged for commit."""
    result = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMR'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    return [f.strip() for f in result.stdout.strip().split('\n') if f.strip()]


def should_skip_file(file_path: str) -> bool:
    """Check if file should be skipped."""
    path = Path(file_path)

    # Skip by extension
    if path.suffix.lower() in SKIP_EXTENSIONS:
        return True

    # Skip by directory
    for part in path.parts:
        if part in SKIP_DIRS:
            return True

    # Skip allow-listed files
    if path.name in ALLOW_LIST_FILES:
        return True

    return False


def scan_file(file_path: str) -> list[dict]:
    """Scan a single file for secrets."""
    findings = []

    if should_skip_file(file_path):
        return findings

    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            lines = content.split('\n')
    except (IOError, OSError):
        return findings

    for pattern in SECRET_PATTERNS:
        for match in re.finditer(pattern.pattern, content):
            # Find line number
            line_num = content[:match.start()].count('\n') + 1

            # Get the actual line content (truncated)
            line_content = lines[line_num - 1] if line_num <= len(lines) else ""
            if len(line_content) > 80:
                line_content = line_content[:77] + "..."

            findings.append({
                'file': file_path,
                'line': line_num,
                'pattern_name': pattern.name,
                'severity': pattern.severity,
                'line_content': line_content,
            })

    return findings


def main():
    """Main entry point."""
    # Get files to scan
    if len(sys.argv) > 1:
        files_to_scan = sys.argv[1:]
    else:
        files_to_scan = get_staged_files()

    if not files_to_scan:
        print("No files to scan")
        sys.exit(0)

    # Scan all files
    all_findings = []
    for file_path in files_to_scan:
        findings = scan_file(file_path)
        all_findings.extend(findings)

    # Report findings
    if not all_findings:
        print("No secrets detected")
        sys.exit(0)

    # Group by severity
    critical = [f for f in all_findings if f['severity'] == 'critical']
    high = [f for f in all_findings if f['severity'] == 'high']
    medium = [f for f in all_findings if f['severity'] == 'medium']

    print("\n" + "=" * 60)
    print("SECRETS SCANNER REPORT")
    print("=" * 60)

    if critical:
        print(f"\nCRITICAL ({len(critical)}):")
        for f in critical:
            print(f"  {f['file']}:{f['line']} - {f['pattern_name']}")
            print(f"    > {f['line_content']}")

    if high:
        print(f"\nHIGH ({len(high)}):")
        for f in high:
            print(f"  {f['file']}:{f['line']} - {f['pattern_name']}")
            print(f"    > {f['line_content']}")

    if medium:
        print(f"\nMEDIUM ({len(medium)}):")
        for f in medium:
            print(f"  {f['file']}:{f['line']} - {f['pattern_name']}")
            print(f"    > {f['line_content']}")

    print("\n" + "=" * 60)

    # Block on critical or high severity
    if critical or high:
        print(f"\nBLOCKED: Found {len(critical)} critical and {len(high)} high severity secrets")
        print("\nTo bypass (NOT recommended):")
        print("  /force-git <command>")
        print("\nTo fix:")
        print("  1. Remove the secrets from the files")
        print("  2. Use environment variables instead")
        print("  3. Add to .gitignore if it's a config file")
        sys.exit(2)  # Exit code 2 blocks the operation in Claude Code

    # Warn on medium severity but allow
    if medium:
        print(f"\nWARNING: Found {len(medium)} potential secrets (medium severity)")
        print("Review before committing - these may be false positives")
        sys.exit(0)


if __name__ == '__main__':
    main()
