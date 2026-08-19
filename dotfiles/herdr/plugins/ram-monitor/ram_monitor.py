#!/usr/bin/env python3
"""RAM Usage Monitor Plugin for Herdr.

Monitors memory usage periodically and sends Herdr notifications when usage
exceeds a configured threshold.
"""

import argparse
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import time


def get_herdr_bin() -> str:
    """Find the herdr executable path."""
    return os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"


def get_pid_file_path() -> Path:
    """Get the path to the PID file for ram_monitor."""
    state_dir = os.environ.get("HERDR_PLUGIN_STATE_DIR")
    if state_dir:
        d = Path(state_dir)
        d.mkdir(parents=True, exist_ok=True)
        return d / "ram_monitor.pid"
    tmp_dir = Path(os.environ.get("TMPDIR", "/tmp"))
    uid = os.getuid() if hasattr(os, "getuid") else "user"
    return tmp_dir / f"herdr_ram_monitor_{uid}.pid"


def is_ram_monitor_process(cmd: str) -> bool:
    """Determine if a process command line is a running ram_monitor worker."""
    if " -c " in cmd or cmd.startswith("python3 -c") or cmd.startswith("python -c"):
        return False
    if any(
        x in cmd
        for x in [
            "vim",
            "nvim",
            "nano",
            "code",
            "emacs",
            "grep",
            "cat",
            "less",
            "more",
            "git",
        ]
    ):
        return False
    return bool(re.search(r"python\d*(?:\.\d+)?\s+.*ram_monitor\.py(?:\s|$)", cmd))


def kill_existing_instances() -> None:
    """Kill any existing ram_monitor processes to prevent duplicate background workers."""
    my_pid = os.getpid()
    target_pids: set[int] = set()

    # 1. Check PID file
    pid_file = get_pid_file_path()
    if pid_file.exists():
        try:
            stored_pid = int(pid_file.read_text().strip())
            if stored_pid != my_pid:
                target_pids.add(stored_pid)
        except Exception:
            pass

    # 2. Search process list for other running instances of ram_monitor.py
    for ps_cmd in (["ps", "-eo", "pid,command"], ["ps", "-Ao", "pid,command"]):
        try:
            out = subprocess.check_output(ps_cmd, text=True)
            for line in out.splitlines():
                line = line.strip()
                if not line:
                    continue
                parts = line.split(None, 1)
                if len(parts) < 2:
                    continue
                pid_str, cmd = parts
                try:
                    pid = int(pid_str)
                except ValueError:
                    continue

                if pid == my_pid:
                    continue

                if is_ram_monitor_process(cmd):
                    target_pids.add(pid)
            break
        except Exception:
            continue

    # 3. Terminate target processes gracefully with SIGTERM
    killed_pids: list[int] = []
    for pid in target_pids:
        try:
            os.kill(pid, signal.SIGTERM)
            killed_pids.append(pid)
        except (ProcessLookupError, PermissionError):
            pass

    # 4. Wait briefly and force kill with SIGKILL if still alive
    if killed_pids:
        time.sleep(0.2)
        for pid in killed_pids:
            try:
                os.kill(pid, 0)
                os.kill(pid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                pass


def parse_numeric(val_str: str) -> float:
    """Extract numeric value from string like '126G', '46.5G', etc."""
    m = re.match(r"^([\d.]+)", val_str.strip())
    return float(m.group(1)) if m else 0.0


def get_memory_info() -> tuple[int, str, str] | tuple[None, None, None]:
    """Retrieve current memory usage metrics: (percentage, total_str, used_str).

    Supports Darwin (macOS) and Linux.
    """
    sys_name = platform.system()

    if sys_name == "Darwin":
        try:
            total_bytes_str = subprocess.check_output(
                ["sysctl", "-n", "hw.memsize"], text=True
            ).strip()
            total_bytes = int(total_bytes_str)

            vm_stat_out = subprocess.check_output(["vm_stat"], text=True)

            page_size = 4096
            m_page = re.search(r"page size of (\d+) bytes", vm_stat_out)
            if m_page:
                page_size = int(m_page.group(1))

            used_pages = 0
            for line in vm_stat_out.splitlines():
                if re.search(r"Pages (active|wired down):", line):
                    m = re.search(r"(\d+)", line.split(":")[-1])
                    if m:
                        used_pages += int(m.group(1))

            total_pages = total_bytes / page_size
            gb = 1024 * 1024 * 1024
            percentage = round((used_pages / total_pages) * 100)
            total_g = int(total_bytes / gb + 0.5)
            used_g = (used_pages * page_size) / gb
            return percentage, f"{total_g}G", f"{used_g:.1f}G"
        except Exception as e:
            sys.stderr.write(f"Error reading Darwin memory info: {e}\n")
            return None, None, None

    elif sys_name == "Linux":
        try:
            free_out = subprocess.check_output(["free", "-h", "--giga"], text=True)
            for line in free_out.splitlines():
                if line.startswith("Mem:"):
                    parts = line.split()
                    total_str = parts[1]
                    used_str = parts[2]
                    total_num = parse_numeric(total_str)
                    used_num = parse_numeric(used_str)
                    percentage = (
                        int((used_num / total_num) * 100) if total_num > 0 else 0
                    )
                    return percentage, total_str, used_str
        except Exception:
            # Fallback to /proc/meminfo if free command is unavailable or fails
            try:
                meminfo = {}
                with open("/proc/meminfo", "r", encoding="utf-8") as f:
                    for line in f:
                        parts = line.split(":")
                        if len(parts) == 2:
                            key = parts[0].strip()
                            val = parts[1].strip().split()[0]
                            meminfo[key] = int(val)
                total_kb = meminfo.get("MemTotal", 0)
                avail_kb = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
                used_kb = max(0, total_kb - avail_kb)
                if total_kb > 0:
                    percentage = round((used_kb / total_kb) * 100)
                    total_gb = int(total_kb / (1024 * 1024) + 0.5)
                    used_gb = used_kb / (1024 * 1024)
                    return percentage, f"{total_gb}G", f"{used_gb:.1f}G"
            except Exception as e:
                sys.stderr.write(f"Error reading Linux memory info: {e}\n")
        return None, None, None

    else:
        sys.stderr.write(f"Unsupported OS: {sys_name}\n")
        return None, None, None


def send_notification(percentage: int, total: str, used: str) -> None:
    """Send Herdr notification about high memory usage."""
    herdr_bin = get_herdr_bin()
    title = "High Memory Usage"
    body = f"RAM usage is at {percentage}% ({used}/{total})"
    try:
        subprocess.run(
            [
                herdr_bin,
                "notification",
                "show",
                title,
                "--body",
                body,
                "--sound",
                "request",
            ],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        sys.stderr.write(f"Failed to send Herdr notification: {e}\n")


def monitor(threshold: int, interval: float, cooldown: float) -> None:
    """Continuously monitor RAM usage and notify on threshold exceedance."""
    kill_existing_instances()

    pid_file = get_pid_file_path()
    try:
        pid_file.write_text(f"{os.getpid()}\n")
    except Exception as e:
        sys.stderr.write(f"Warning: could not write PID file: {e}\n")

    running = True

    def handle_signal(signum, frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    was_high = False
    last_notified = 0.0

    try:
        while running:
            percentage, total, used = get_memory_info()
            if percentage is not None and total is not None and used is not None:
                now = time.time()
                if percentage >= threshold:
                    if not was_high or (now - last_notified) >= cooldown:
                        send_notification(percentage, total, used)
                        last_notified = now
                        was_high = True
                else:
                    was_high = False

            time.sleep(interval)
    finally:
        try:
            if pid_file.exists() and pid_file.read_text().strip() == str(os.getpid()):
                pid_file.unlink(missing_ok=True)
        except Exception:
            pass


def check_once(threshold: int) -> None:
    """Check memory usage once and print status / notify if over threshold."""
    percentage, total, used = get_memory_info()
    if percentage is None:
        sys.stderr.write("Could not retrieve memory information.\n")
        sys.exit(1)

    print(f"RAM usage: {percentage}% ({used}/{total}) (threshold: {threshold}%)")
    if percentage >= threshold:
        send_notification(percentage, total, used)


def main():
    default_threshold = int(
        os.environ.get("HERDR_RAM_THRESHOLD")
        or os.environ.get("HERDR_MEMORY_THRESHOLD")
        or 60
    )
    default_interval = float(os.environ.get("HERDR_RAM_INTERVAL") or 5.0)
    default_cooldown = float(os.environ.get("HERDR_RAM_COOLDOWN") or 60.0)

    parser = argparse.ArgumentParser(description="RAM Monitor Plugin for Herdr")
    parser.add_argument(
        "--threshold",
        "-t",
        type=int,
        default=default_threshold,
        help=f"Memory usage percentage threshold (default: {default_threshold})",
    )
    parser.add_argument(
        "--interval",
        "-i",
        type=float,
        default=default_interval,
        help=f"Check interval in seconds (default: {default_interval})",
    )
    parser.add_argument(
        "--cooldown",
        "-c",
        type=float,
        default=default_cooldown,
        help=(
            "Minimum seconds between repeated high memory notifications"
            f" (default: {default_cooldown})"
        ),
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Check memory usage once and exit",
    )

    args = parser.parse_args()

    if args.once:
        check_once(args.threshold)
    else:
        monitor(args.threshold, args.interval, args.cooldown)


if __name__ == "__main__":
    main()
