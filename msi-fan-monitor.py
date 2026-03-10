#!/usr/bin/env python3
"""
MSI Fan Monitor - Real-time temperature and fan speed monitoring
Uses Rich library for smooth rendering without flickering
"""

import time
import sys
from pathlib import Path
from datetime import datetime

try:
    from rich.live import Live
    from rich.table import Table
    from rich.console import Console
    from rich.panel import Panel
    from rich.layout import Layout
    from rich.text import Text
except ImportError:
    print("ERROR: Rich library not installed")
    print("Install with: pip3 install rich")
    sys.exit(1)

MSI_EC = Path("/sys/devices/platform/msi-ec")

# Temperature thresholds
TEMP_CRITICAL = 80
TEMP_HIGH = 70

console = Console()


def read_file_safe(path):
    """Read a file and return its content, or empty string on error"""
    try:
        if path.exists():
            return path.read_text().strip()
    except Exception:
        pass
    return ""


def get_temperature(sensor_type):
    """Get temperature for a specific sensor (cpu/gpu)"""
    temp_file = MSI_EC / sensor_type / "realtime_temperature"
    temp_str = read_file_safe(temp_file)
    try:
        return int(temp_str)
    except (ValueError, TypeError):
        return 0


def get_fan_speed(sensor_type):
    """Get fan speed for a specific sensor (cpu/gpu)"""
    fan_file = MSI_EC / sensor_type / "realtime_fan_speed"
    speed_str = read_file_safe(fan_file)
    try:
        return int(speed_str)
    except (ValueError, TypeError):
        return 0


def get_fan_mode():
    """Get current fan mode"""
    mode = read_file_safe(MSI_EC / "fan_mode")
    return mode if mode else "unknown"


def get_cooler_boost():
    """Get cooler boost status"""
    boost = read_file_safe(MSI_EC / "cooler_boost")
    return boost == "on"


def temperature_color(temp):
    """Return color based on temperature threshold"""
    if temp >= TEMP_CRITICAL:
        return "bold red"
    elif temp >= TEMP_HIGH:
        return "bold yellow"
    else:
        return "bold green"


def temperature_status(temp):
    """Return status text based on temperature threshold"""
    if temp >= TEMP_CRITICAL:
        return "CRITICAL ⚠️"
    elif temp >= TEMP_HIGH:
        return "HIGH"
    else:
        return "NORMAL"


def generate_display():
    """Generate the Rich display layout"""
    # Get current readings
    cpu_temp = get_temperature("cpu")
    gpu_temp = get_temperature("gpu")
    cpu_fan = get_fan_speed("cpu")
    gpu_fan = get_fan_speed("gpu")
    fan_mode = get_fan_mode()
    cooler_boost = get_cooler_boost()
    
    # Calculate max temperature
    max_temp = max(cpu_temp, gpu_temp)
    
    # Create timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Create main layout
    layout = Layout()
    layout.split_column(
        Layout(name="header", size=3),
        Layout(name="body"),
        Layout(name="footer", size=3)
    )
    
    # Header with title and timestamp
    header_text = Text()
    header_text.append("🌡️  MSI Fan Monitor  ", style="bold cyan")
    header_text.append(f"  {timestamp}", style="dim")
    layout["header"].update(Panel(header_text, border_style="cyan"))
    
    # Body with temperature and fan table
    body_layout = Layout()
    body_layout.split_row(
        Layout(name="temps"),
        Layout(name="info")
    )
    
    # Temperature table
    temp_table = Table(title="🌡️  Temperatures", show_header=True, header_style="bold cyan")
    temp_table.add_column("Sensor", style="bold", width=12)
    temp_table.add_column("Temp", justify="right", width=10)
    temp_table.add_column("Status", justify="center", width=15)
    temp_table.add_column("Fan Speed", justify="right", width=12)
    
    # Add CPU row
    cpu_color = temperature_color(cpu_temp)
    cpu_status = temperature_status(cpu_temp)
    temp_table.add_row(
        "CPU",
        f"[{cpu_color}]{cpu_temp}°C[/{cpu_color}]",
        f"[{cpu_color}]{cpu_status}[/{cpu_color}]",
        f"{cpu_fan} RPM"
    )
    
    # Add GPU row
    gpu_color = temperature_color(gpu_temp)
    gpu_status = temperature_status(gpu_temp)
    temp_table.add_row(
        "GPU",
        f"[{gpu_color}]{gpu_temp}°C[/{gpu_color}]",
        f"[{gpu_color}]{gpu_status}[/{gpu_color}]",
        f"{gpu_fan} RPM"
    )
    
    # Add max temperature row
    temp_table.add_section()
    max_color = temperature_color(max_temp)
    max_status = temperature_status(max_temp)
    temp_table.add_row(
        "[bold]MAX[/bold]",
        f"[{max_color}]{max_temp}°C[/{max_color}]",
        f"[{max_color}]{max_status}[/{max_color}]",
        ""
    )
    
    # Info panel
    info_text = Text()
    info_text.append("Fan Mode: ", style="bold")
    info_text.append(f"{fan_mode}\n\n", style="cyan")
    
    info_text.append("Cooler Boost: ", style="bold")
    if cooler_boost:
        info_text.append("ON 🔥", style="bold red")
    else:
        info_text.append("OFF", style="dim")
    
    info_text.append("\n\n")
    info_text.append("Thresholds:\n", style="bold underline")
    info_text.append(f"  CRITICAL: ≥ {TEMP_CRITICAL}°C\n", style="red")
    info_text.append(f"  HIGH: ≥ {TEMP_HIGH}°C\n", style="yellow")
    info_text.append(f"  NORMAL: < {TEMP_HIGH}°C", style="green")
    
    info_panel = Panel(info_text, title="⚙️  Settings", border_style="blue")
    
    body_layout["temps"].update(temp_table)
    body_layout["info"].update(info_panel)
    layout["body"].update(body_layout)
    
    # Footer with instructions
    footer_text = Text()
    footer_text.append("Press ", style="dim")
    footer_text.append("Ctrl+C", style="bold red")
    footer_text.append(" to exit", style="dim")
    layout["footer"].update(Panel(footer_text, border_style="dim"))
    
    return layout


def main():
    """Main function to run the monitor"""
    # Check if msi-ec is available
    if not MSI_EC.exists():
        console.print("[bold red]ERROR:[/bold red] msi-ec not available at /sys/devices/platform/msi-ec")
        console.print("Make sure the msi-ec module is loaded")
        sys.exit(1)
    
    try:
        # Use Rich Live display for smooth updates without flickering
        with Live(generate_display(), refresh_per_second=2, screen=True) as live:
            while True:
                time.sleep(0.5)
                live.update(generate_display())
    except KeyboardInterrupt:
        console.print("\n[dim]Monitor stopped[/dim]")
        sys.exit(0)


if __name__ == "__main__":
    main()
