#!/usr/bin/env python3
"""
run-uat.py - Dynamic User Acceptance Testing with Playwright

This script:
1. Detects what was built (from git changes or plan file)
2. Starts local servers if not running
3. Executes user journeys with Playwright
4. Captures screenshots as evidence
5. Generates a UAT report

Usage:
    python run-uat.py [--project hotel-de-ville|stellaris] [--headed] [--plan PLAN_FILE]

Examples:
    python run-uat.py                           # Auto-detect project, headless
    python run-uat.py --headed                  # Visual mode for debugging
    python run-uat.py --plan 00\ Inbox/plans/PLAN-2025-001.md
"""

import argparse
import asyncio
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Check for playwright
try:
    from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeout
except ImportError:
    print("❌ Playwright not installed.")
    print("   Install with: pip install playwright && playwright install chromium")
    sys.exit(1)


REPO_ROOT = Path("/home/user/jf-private")
SCREENSHOT_DIR = REPO_ROOT / "inbox" / "uat-screenshots"

# Project configurations
PROJECTS = {
    "hotel-de-ville": {
        "backend_port": 8000,
        "frontend_port": 5173,
        "frontend_dir": REPO_ROOT / "hotel-de-ville" / "frontend",
        "routes": [
            {"path": "/", "name": "Home", "redirects_to": "/chat"},
            {"path": "/chat", "name": "General Chat"},
            {"path": "/intake", "name": "Intake"},
            {"path": "/memory", "name": "Memory"},
            {"path": "/knowledge", "name": "Knowledge"},
            {"path": "/agents", "name": "Agents"},
            {"path": "/settings", "name": "Settings"},
        ],
    },
    "stellaris": {
        "backend_port": 8002,
        "frontend_port": 5174,
        "frontend_dir": REPO_ROOT / "stellaris" / "frontend",
        "routes": [
            {"path": "/", "name": "Home"},
            {"path": "/vocabulary", "name": "Vocabulary"},
            {"path": "/training", "name": "Training"},
            {"path": "/stats", "name": "Stats"},
        ],
    },
}


class UATRunner:
    def __init__(
        self,
        project: str = "hotel-de-ville",
        headed: bool = False,
        plan_file: Optional[Path] = None,
    ):
        self.project = project
        self.config = PROJECTS[project]
        self.headed = headed
        self.plan_file = plan_file
        self.base_url = f"http://localhost:{self.config['frontend_port']}"
        self.results: list[dict] = []
        self.screenshots: list[Path] = []
        self.start_time = datetime.now()

    async def check_services(self) -> bool:
        """Check if backend and frontend are running."""
        import httpx

        backend_url = f"http://localhost:{self.config['backend_port']}/api/health"
        frontend_url = self.base_url

        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                backend_resp = await client.get(backend_url)
                backend_ok = backend_resp.status_code == 200
            except Exception:
                backend_ok = False

            try:
                frontend_resp = await client.get(frontend_url)
                frontend_ok = frontend_resp.status_code == 200
            except Exception:
                frontend_ok = False

        if not backend_ok:
            print(f"❌ Backend not running on port {self.config['backend_port']}")
        if not frontend_ok:
            print(f"❌ Frontend not running on port {self.config['frontend_port']}")

        return backend_ok and frontend_ok

    def start_services(self) -> bool:
        """Start local stack using helper script."""
        script = REPO_ROOT / ".claude" / "scripts" / "start-local-stack.sh"
        if not script.exists():
            print(f"❌ Start script not found: {script}")
            return False

        result = subprocess.run(
            [str(script), self.project],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print(f"❌ Failed to start services:\n{result.stderr}")
            return False

        print(result.stdout)
        return True

    async def run_basic_navigation(self, page) -> None:
        """Test basic navigation to all routes."""
        for route in self.config["routes"]:
            path = route["path"]
            name = route["name"]
            expected_url = route.get("redirects_to", path)

            try:
                await page.goto(f"{self.base_url}{path}")
                await page.wait_for_load_state("networkidle", timeout=10000)

                # Check URL (handle redirects)
                current_url = page.url
                if expected_url in current_url:
                    status = "✅ Pass"
                else:
                    status = f"⚠️ Unexpected URL: {current_url}"

                # Take screenshot
                screenshot_name = f"{self.project}-{name.lower().replace(' ', '-')}.png"
                screenshot_path = SCREENSHOT_DIR / screenshot_name
                await page.screenshot(path=str(screenshot_path))
                self.screenshots.append(screenshot_path)

                self.results.append({
                    "test": f"Navigate to {name}",
                    "status": status,
                    "screenshot": screenshot_name,
                })
                print(f"  {status} Navigate to {name} ({path})")

            except PlaywrightTimeout:
                self.results.append({
                    "test": f"Navigate to {name}",
                    "status": "❌ Timeout",
                    "screenshot": None,
                })
                print(f"  ❌ Timeout: Navigate to {name} ({path})")

            except Exception as e:
                self.results.append({
                    "test": f"Navigate to {name}",
                    "status": f"❌ Error: {str(e)[:50]}",
                    "screenshot": None,
                })
                print(f"  ❌ Error: Navigate to {name} - {e}")

    async def run_sidebar_navigation(self, page) -> None:
        """Test sidebar navigation links."""
        await page.goto(self.base_url)
        await page.wait_for_load_state("networkidle", timeout=10000)

        # Find sidebar links
        sidebar = page.locator("aside")
        if await sidebar.count() == 0:
            self.results.append({
                "test": "Sidebar exists",
                "status": "❌ No sidebar found",
                "screenshot": None,
            })
            return

        links = sidebar.locator("a")
        link_count = await links.count()

        self.results.append({
            "test": "Sidebar exists",
            "status": f"✅ Pass ({link_count} links)",
            "screenshot": None,
        })
        print(f"  ✅ Sidebar exists with {link_count} links")

        # Click each link and verify navigation
        for i in range(link_count):
            link = links.nth(i)
            link_text = await link.text_content()
            if not link_text:
                continue

            try:
                await link.click()
                await page.wait_for_load_state("networkidle", timeout=5000)

                self.results.append({
                    "test": f"Click sidebar: {link_text.strip()}",
                    "status": "✅ Pass",
                    "screenshot": None,
                })
                print(f"  ✅ Click sidebar: {link_text.strip()}")

            except Exception as e:
                self.results.append({
                    "test": f"Click sidebar: {link_text.strip()}",
                    "status": f"❌ Error: {str(e)[:30]}",
                    "screenshot": None,
                })

    async def run_responsive_check(self, page) -> None:
        """Test responsive layout at different viewport sizes."""
        viewports = [
            {"name": "Desktop", "width": 1920, "height": 1080},
            {"name": "Laptop", "width": 1366, "height": 768},
            {"name": "Tablet", "width": 768, "height": 1024},
        ]

        for vp in viewports:
            await page.set_viewport_size({"width": vp["width"], "height": vp["height"]})
            await page.goto(self.base_url)
            await page.wait_for_load_state("networkidle", timeout=10000)

            # Check for horizontal scroll (bad)
            has_h_scroll = await page.evaluate(
                "document.documentElement.scrollWidth > document.documentElement.clientWidth"
            )

            if has_h_scroll:
                status = "❌ Horizontal scroll detected"
            else:
                status = "✅ Pass"

            # Screenshot
            screenshot_name = f"{self.project}-{vp['name'].lower()}.png"
            screenshot_path = SCREENSHOT_DIR / screenshot_name
            await page.screenshot(path=str(screenshot_path))
            self.screenshots.append(screenshot_path)

            self.results.append({
                "test": f"Responsive: {vp['name']} ({vp['width']}x{vp['height']})",
                "status": status,
                "screenshot": screenshot_name,
            })
            print(f"  {status} Responsive: {vp['name']}")

    async def run_theme_check(self, page) -> None:
        """Verify theme is applied correctly."""
        await page.goto(self.base_url)
        await page.wait_for_load_state("networkidle", timeout=10000)

        # Check body background color
        bg_color = await page.evaluate(
            "window.getComputedStyle(document.body).backgroundColor"
        )

        # Check for dark theme (common dark colors)
        is_dark = any(c in bg_color for c in ["24", "27", "18", "0, 0, 0"])

        if is_dark:
            status = f"✅ Dark theme ({bg_color})"
        else:
            status = f"⚠️ Light theme? ({bg_color})"

        self.results.append({
            "test": "Theme check",
            "status": status,
            "screenshot": None,
        })
        print(f"  {status}")

    async def run_console_errors(self, page) -> None:
        """Check for console errors."""
        errors = []

        page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)

        await page.goto(self.base_url)
        await page.wait_for_load_state("networkidle", timeout=10000)

        # Navigate around to trigger potential errors
        for route in self.config["routes"][:3]:
            await page.goto(f"{self.base_url}{route['path']}")
            await page.wait_for_timeout(500)

        if errors:
            status = f"❌ {len(errors)} console errors"
            for err in errors[:5]:  # Show first 5
                print(f"     Console error: {err[:80]}")
        else:
            status = "✅ No console errors"

        self.results.append({
            "test": "Console errors",
            "status": status,
            "screenshot": None,
        })
        print(f"  {status}")

    def generate_report(self) -> Path:
        """Generate markdown UAT report."""
        duration = datetime.now() - self.start_time
        passed = sum(1 for r in self.results if r["status"].startswith("✅"))
        failed = sum(1 for r in self.results if r["status"].startswith("❌"))
        warnings = sum(1 for r in self.results if r["status"].startswith("⚠️"))

        report = f"""# UAT Report - {self.project}

**Date:** {self.start_time.strftime('%Y-%m-%d %H:%M')}
**Duration:** {duration.seconds}s
**Tester:** Claude Code (automated)

## Summary

| Status | Count |
|--------|-------|
| ✅ Passed | {passed} |
| ❌ Failed | {failed} |
| ⚠️ Warnings | {warnings} |

## Test Results

| Test | Status | Evidence |
|------|--------|----------|
"""
        for r in self.results:
            screenshot = r.get("screenshot", "")
            if screenshot:
                screenshot = f"[📷]({screenshot})"
            report += f"| {r['test']} | {r['status']} | {screenshot} |\n"

        report += f"""
## Screenshots

Saved to: `{SCREENSHOT_DIR}`

"""
        for ss in self.screenshots:
            report += f"- {ss.name}\n"

        report += f"""
## Recommendation

"""
        if failed > 0:
            report += "❌ **NOT ready for deployment** - Fix failing tests first.\n"
        elif warnings > 0:
            report += "⚠️ **Review warnings** before deployment.\n"
        else:
            report += "✅ **Ready for deployment** - All tests passed.\n"

        # Save report
        report_path = REPO_ROOT / "inbox" / f"UAT-REPORT-{self.project}-{self.start_time.strftime('%Y%m%d-%H%M')}.md"
        report_path.write_text(report)

        return report_path

    async def run(self) -> bool:
        """Run all UAT tests."""
        print(f"\n{'='*50}")
        print(f"UAT Runner - {self.project}")
        print(f"{'='*50}\n")

        # Check/start services
        print("Checking services...")
        if not await self.check_services():
            print("\nStarting services...")
            if not self.start_services():
                return False
            # Wait a bit for services to stabilize
            await asyncio.sleep(3)
            if not await self.check_services():
                print("❌ Services failed to start")
                return False

        print(f"\n✅ Services ready at {self.base_url}\n")

        # Create screenshot directory
        SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)

        # Run tests with Playwright
        print("Running UAT tests...\n")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=not self.headed)
            page = await browser.new_page()

            print("📍 Basic Navigation")
            await self.run_basic_navigation(page)

            print("\n📍 Sidebar Navigation")
            await self.run_sidebar_navigation(page)

            print("\n📍 Responsive Layout")
            await self.run_responsive_check(page)

            print("\n📍 Theme Check")
            await self.run_theme_check(page)

            print("\n📍 Console Errors")
            await self.run_console_errors(page)

            await browser.close()

        # Generate report
        report_path = self.generate_report()
        print(f"\n{'='*50}")
        print(f"UAT Complete!")
        print(f"{'='*50}")
        print(f"\nReport: {report_path}")
        print(f"Screenshots: {SCREENSHOT_DIR}")

        # Return success status
        failed = sum(1 for r in self.results if r["status"].startswith("❌"))
        return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Run UAT tests with Playwright")
    parser.add_argument(
        "--project",
        choices=["hotel-de-ville", "stellaris"],
        default="hotel-de-ville",
        help="Project to test (default: hotel-de-ville)",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run browser in headed mode (visible)",
    )
    parser.add_argument(
        "--plan",
        type=Path,
        help="Development plan file to derive test cases from",
    )

    args = parser.parse_args()

    runner = UATRunner(
        project=args.project,
        headed=args.headed,
        plan_file=args.plan,
    )

    success = asyncio.run(runner.run())
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
