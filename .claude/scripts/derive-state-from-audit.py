#!/usr/bin/env python3
"""
derive-state-from-audit.py - Derive plan states from audit log

This script treats the audit log (JSONL) as the source of truth and derives
the current state of all plans by replaying events in order.

Usage:
    python3 derive-state-from-audit.py [audit_log_path]

    If no path is provided, defaults to "inbox/audit_log.jsonl"

Output:
    JSON object mapping plan IDs to their derived states
"""

import json
import sys
from pathlib import Path
from typing import Any


def derive_state(audit_log_path: str) -> dict[str, Any]:
    """
    Derive current state from audit log events.

    Processes events in order and applies state machine transitions:
    - PLAN_SUBMITTED -> QUEUED
    - RISK_ASSESSED -> (updates risk fields)
    - EXECUTION_QUEUED -> READY
    - TPM_SPAWNED -> EXECUTING
    - EXECUTION_COMPLETE -> SHIPPED
    - EXECUTION_FAILED -> FAILED

    Args:
        audit_log_path: Path to the audit log JSONL file

    Returns:
        Dictionary mapping plan IDs to their state objects
    """
    plans: dict[str, Any] = {}

    try:
        with open(audit_log_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue

                try:
                    event = json.loads(line)
                except json.JSONDecodeError as e:
                    print(f"Warning: Invalid JSON on line {line_num}: {e}",
                          file=sys.stderr)
                    continue

                plan_id = event.get('plan_id')
                if not plan_id or plan_id == 'ALL':
                    continue

                event_type = event.get('event', '')
                timestamp = event.get('timestamp', '')
                details = event.get('details', {})

                # Initialize plan if first time seeing it
                if plan_id not in plans:
                    plans[plan_id] = {
                        'status': 'UNKNOWN',
                        'events': [],
                        'risk_score': None,
                        'risk_approved': False,
                        'submitted_at': None,
                        'execution_started': None,
                        'execution_completed': None,
                        'pr_url': None,
                        'priority': None,
                    }

                # Record event
                plans[plan_id]['events'].append({
                    'type': event_type,
                    'timestamp': timestamp,
                })

                # State machine transitions
                if event_type == 'PLAN_SUBMITTED':
                    plans[plan_id]['status'] = 'QUEUED'
                    plans[plan_id]['submitted_at'] = timestamp
                    plans[plan_id]['priority'] = details.get('priority')

                elif event_type == 'RISK_ASSESSED':
                    plans[plan_id]['risk_score'] = details.get('overall_score')
                    plans[plan_id]['risk_approved'] = (
                        details.get('decision') == 'APPROVED'
                    )

                elif event_type == 'EXECUTION_QUEUED':
                    plans[plan_id]['status'] = 'READY'

                elif event_type == 'TPM_SPAWNED':
                    plans[plan_id]['status'] = 'EXECUTING'
                    plans[plan_id]['execution_started'] = timestamp
                    plans[plan_id]['tpm_agent_id'] = details.get('tpm_agent_id')

                elif event_type == 'EXECUTION_COMPLETE':
                    plans[plan_id]['status'] = 'SHIPPED'
                    plans[plan_id]['execution_completed'] = timestamp
                    plans[plan_id]['pr_url'] = details.get('pr_url')

                elif event_type == 'EXECUTION_FAILED':
                    plans[plan_id]['status'] = 'FAILED'
                    plans[plan_id]['failure_reason'] = details.get('reason')

                elif event_type == 'STATE_RECONCILIATION':
                    # Manual reconciliation event - check if status was corrected
                    if 'corrected_status' in details:
                        plans[plan_id]['status'] = details['corrected_status']

    except FileNotFoundError:
        print(f"Error: Audit log not found at {audit_log_path}", file=sys.stderr)
        return {}

    return plans


def compare_with_state_file(
    derived: dict[str, Any],
    state_file_path: str
) -> list[dict[str, Any]]:
    """
    Compare derived state with .state.json and report discrepancies.

    Args:
        derived: State derived from audit log
        state_file_path: Path to .state.json

    Returns:
        List of discrepancy objects
    """
    discrepancies = []

    try:
        with open(state_file_path, 'r', encoding='utf-8') as f:
            state_file = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        return [{'error': f'Could not read state file: {e}'}]

    file_plans = state_file.get('plans', {})

    # Check plans in derived state
    for plan_id, derived_plan in derived.items():
        if plan_id not in file_plans:
            discrepancies.append({
                'plan_id': plan_id,
                'issue': 'missing_from_state_file',
                'derived_status': derived_plan['status'],
            })
            continue

        file_plan = file_plans[plan_id]
        file_status = file_plan.get('status', 'UNKNOWN')
        derived_status = derived_plan['status']

        if file_status != derived_status:
            discrepancies.append({
                'plan_id': plan_id,
                'issue': 'status_mismatch',
                'state_file_status': file_status,
                'audit_derived_status': derived_status,
            })

    # Check plans in state file but not in audit log
    for plan_id in file_plans:
        if plan_id not in derived:
            discrepancies.append({
                'plan_id': plan_id,
                'issue': 'missing_from_audit_log',
                'state_file_status': file_plans[plan_id].get('status'),
            })

    return discrepancies


def main() -> None:
    """Main entry point."""
    # Determine audit log path
    if len(sys.argv) > 1:
        audit_path = sys.argv[1]
    else:
        audit_path = 'inbox/audit_log.jsonl'

    # Derive state from audit log
    state = derive_state(audit_path)

    # Check for comparison mode
    if len(sys.argv) > 2 and sys.argv[2] == '--compare':
        state_file_path = (
            sys.argv[3] if len(sys.argv) > 3
            else 'inbox/plans/.state.json'
        )
        discrepancies = compare_with_state_file(state, state_file_path)

        output = {
            'derived_state': state,
            'discrepancies': discrepancies,
            'discrepancy_count': len(discrepancies),
        }
        print(json.dumps(output, indent=2))
    else:
        # Just output derived state
        # Remove events list for cleaner output
        clean_state = {}
        for plan_id, plan in state.items():
            clean_plan = {k: v for k, v in plan.items() if k != 'events'}
            clean_plan['event_count'] = len(plan['events'])
            clean_state[plan_id] = clean_plan

        print(json.dumps(clean_state, indent=2))


if __name__ == '__main__':
    main()
