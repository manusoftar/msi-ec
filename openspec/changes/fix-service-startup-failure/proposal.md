## Why

The msi-ec-custom systemd service is failing to start, preventing the custom MSI EC kernel module from being loaded automatically at boot. The service exited with status 1/FAILURE, leaving users without fan control and other EC features until the issue is manually resolved.

## What Changes

- Diagnose root cause of service startup failure (module not built, path issues, permissions, or kernel compatibility)
- Fix the service configuration to handle common failure scenarios gracefully
- Add proper error handling and logging to identify failures quickly
- Ensure the module build process completes successfully before service attempts to load it
- Add pre-flight checks in the service to validate module availability

## Capabilities

### New Capabilities
- `service-diagnostics`: Logging and error reporting to diagnose service failures
- `service-resilience`: Pre-flight checks and error handling for robust service startup

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **Service File**: msi-ec-custom.service will be modified with better error handling
- **Build Process**: May need to ensure msi-ec.ko is built before service starts
- **User Experience**: Service will start reliably with clear error messages if something goes wrong
- **SystemD Integration**: Improved service dependencies and error reporting
