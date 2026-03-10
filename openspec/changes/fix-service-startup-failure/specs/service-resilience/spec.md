## ADDED Requirements

### Requirement: Service SHALL validate module file existence before loading

The service wrapper script MUST check that the kernel module file exists at the expected path before attempting to execute insmod.

#### Scenario: Module file exists
- **WHEN** the msi-ec.ko file exists at the configured path
- **THEN** the script proceeds to load the module

#### Scenario: Module file missing
- **WHEN** the msi-ec.ko file does not exist
- **THEN** the script logs an error and exits without attempting insmod

### Requirement: Service SHALL validate file permissions

The service wrapper script MUST verify the module file is readable before attempting to load it.

#### Scenario: File is readable
- **WHEN** the module file exists and has appropriate read permissions
- **THEN** the script proceeds with module loading

#### Scenario: File lacks permissions
- **WHEN** the module file exists but is not readable
- **THEN** the script logs a permission error and exits without attempting insmod

### Requirement: Service SHALL handle pre-existing module gracefully

The service wrapper script MUST detect if the msi-ec module is already loaded and handle this condition appropriately.

#### Scenario: Module already loaded
- **WHEN** the msi-ec module is already present in the kernel
- **THEN** the script unloads the existing module before loading the new one (matching ExecStartPre behavior)

#### Scenario: Module load succeeds
- **WHEN** all pre-flight checks pass and insmod executes successfully
- **THEN** the script exits with code 0

### Requirement: Service SHALL fail fast on validation errors

When pre-flight checks detect issues, the service MUST exit immediately without attempting module operations.

#### Scenario: Early exit on missing file
- **WHEN** the module file does not exist
- **THEN** the script exits before attempting modprobe or insmod commands

#### Scenario: Early exit on permission error
- **WHEN** the module file exists but is not readable
- **THEN** the script exits before attempting to load the module
