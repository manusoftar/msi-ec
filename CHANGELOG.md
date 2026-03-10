# Changelog

## [Unreleased] - 2026-03-09

### Added
- **Python-based fan monitor** (`msi-fan-monitor.py`) using Rich library
  - Smooth real-time display without flickering
  - Color-coded temperature states (NORMAL/HIGH/CRITICAL)
  - Professional layout with tables and panels
  - Displays CPU/GPU temperatures and fan speeds
  
- **Service startup validation** (`msi-ec-load.sh`)
  - Pre-flight checks for module file existence and permissions
  - Detailed error messages with actionable guidance
  - Specific exit codes for different failure scenarios:
    - 0: Success
    - 1: Module file not found
    - 2: Permission denied
    - 3: Kernel load failed

- **Source files from upstream**
  - `msi-ec.c`: Main kernel module source
  - `ec_memory_configuration.h`: EC memory configuration header

- **Troubleshooting documentation** in README
  - Service startup issues and solutions
  - Exit code reference table
  - Common issues and resolutions

### Fixed
- **Service startup failure** - Module was missing source files
  - Retrieved `msi-ec.c` and `ec_memory_configuration.h` from upstream
  - Successfully built kernel module (`msi-ec.ko`)
  
- **Fan daemon unary operator error**
  - Fixed temperature parsing to handle empty/non-numeric values
  - Added safe integer validation for all temperature readings
  - Improved ACPI temperature parsing robustness

- **Monitor flickering issue**
  - Replaced bash clear/redraw with Python Rich Live display
  - Smooth updates with partial screen refresh
  - Better user experience with professional formatting

### Changed
- **Enhanced `msi-ec-smart-load.sh`**
  - Added comprehensive error handling
  - Improved error messages with full context
  - Better diagnostic information for troubleshooting

- **Updated `msi-fan-daemon.sh`**
  - Safe temperature reading functions
  - Robust numeric validation
  - Support for calling Python monitor via `monitor` command
  - Fixed all comparison operators to use quoted variables

- **Improved `msi-fan-daemon-smart.sh`**
  - Now passes CLI arguments to daemon
  - Enables `monitor` mode functionality

- **Updated .gitignore**
  - Better coverage of build artifacts
  - Python cache files
  - IDE and editor temporary files

### Technical Details

**Service Architecture:**
- Primary service: `msi-ec-custom.service` → `/usr/local/bin/msi-ec-smart-load`
- Fan daemon: `msi-fan-daemon.service` → `/usr/local/bin/msi-fan-daemon`
- Monitor tool: `msi-fan-monitor.py` (called via `msi-fan-daemon monitor`)

**Temperature Thresholds:**
- CRITICAL: ≥ 80°C
- HIGH: ≥ 70°C  
- NORMAL: < 70°C

**Usage:**
```bash
# Monitor temperatures in real-time
sudo msi-fan-daemon monitor

# View current status
sudo msi-fan-control.sh status

# Check service status
sudo systemctl status msi-ec-custom
sudo systemctl status msi-fan-daemon
```
