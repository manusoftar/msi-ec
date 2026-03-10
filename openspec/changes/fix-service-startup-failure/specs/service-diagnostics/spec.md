## ADDED Requirements

### Requirement: Service SHALL log failure reasons to systemd journal

The service wrapper script SHALL write specific error messages to stderr (captured by systemd journal) identifying the root cause of any startup failure.

#### Scenario: Module file not found
- **WHEN** the msi-ec.ko file does not exist at the expected path
- **THEN** the service logs "Module file not found at <path>" to stderr and exits with code 1

#### Scenario: Module file not readable
- **WHEN** the msi-ec.ko file exists but cannot be read due to permissions
- **THEN** the service logs "Module file not readable: permission denied" to stderr and exits with code 2

#### Scenario: Kernel module load failure
- **WHEN** insmod command fails to load the module
- **THEN** the service logs "Failed to load module: <error>" with kernel error details to stderr and exits with code 3

### Requirement: Service SHALL use distinct exit codes for failure types

The service wrapper script SHALL exit with specific numeric codes to distinguish between different failure scenarios for diagnostic purposes.

#### Scenario: Different exit codes for different failures
- **WHEN** the service encounters any failure condition
- **THEN** it exits with a unique code (1=file not found, 2=permission denied, 3=insmod failed, 0=success)

### Requirement: Error messages SHALL be actionable

Error messages logged to the journal SHALL include enough context for users to resolve the issue without consulting additional documentation.

#### Scenario: Error includes expected path
- **WHEN** module file is not found
- **THEN** error message includes the full path where the module was expected

#### Scenario: Error suggests next steps
- **WHEN** module file doesn't exist
- **THEN** error message suggests running the build process (make/dkms)
