#!/bin/bash
#
# MSI EC Module Loader with Pre-flight Validation
# 
# This script loads the custom MSI EC kernel module with proper error handling
# and validation. It provides detailed error messages to help diagnose issues.
#
# Exit Codes:
#   0 - Success: Module loaded successfully
#   1 - Module file not found (likely not built yet)
#   2 - Module file not readable (permission issue)
#   3 - Module load failed (kernel/compatibility issue)
#
# Usage: Called by msi-ec-custom.service at boot time
#

# Module file location (matches installation path)
MODULE_PATH="/home/manusoftar/Git/msi-ec/msi-ec.ko"

# Step 1: Check if module file exists
if [ ! -f "$MODULE_PATH" ]; then
    echo "ERROR: Module file not found at $MODULE_PATH" >&2
    echo "Please build the module first using 'make' or 'sudo make dkms-install'" >&2
    exit 1
fi

# Step 2: Check if module file is readable
if [ ! -r "$MODULE_PATH" ]; then
    echo "ERROR: Module file not readable: permission denied" >&2
    echo "File exists at $MODULE_PATH but cannot be read" >&2
    echo "Check file permissions with: ls -l $MODULE_PATH" >&2
    exit 2
fi

# Step 3: Remove pre-existing msi-ec module if loaded
# This matches the ExecStartPre behavior from the service file
/sbin/modprobe -r msi-ec 2>/dev/null
/sbin/rmmod msi_ec 2>/dev/null

# Step 4: Load the module
if ! /sbin/insmod "$MODULE_PATH" 2>&1; then
    # Capture the actual error from insmod
    ERROR_OUTPUT=$(/sbin/insmod "$MODULE_PATH" 2>&1)
    echo "ERROR: Failed to load module: $ERROR_OUTPUT" >&2
    echo "Module file: $MODULE_PATH" >&2
    echo "This may indicate a kernel compatibility issue" >&2
    exit 3
fi

# Success!
echo "MSI EC module loaded successfully from $MODULE_PATH"
exit 0
