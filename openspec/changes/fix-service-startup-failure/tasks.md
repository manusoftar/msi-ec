## 1. Create Wrapper Script

- [x] 1.1 Create msi-ec-load.sh wrapper script with shebang and header comments
- [x] 1.2 Define MODULE_PATH variable pointing to msi-ec.ko location
- [x] 1.3 Implement file existence check with error message and exit code 1
- [x] 1.4 Implement file readability check with error message and exit code 2
- [x] 1.5 Add logic to remove pre-existing msi-ec module if loaded
- [x] 1.6 Implement insmod command with error capture and exit code 3 on failure
- [x] 1.7 Add success message logging for successful module load
- [x] 1.8 Document exit codes in script header comments

## 2. Update Service Configuration

- [x] 2.1 Update msi-ec-custom.service ExecStart to call wrapper script
- [x] 2.2 Verify ExecStartPre commands are compatible with wrapper approach
- [x] 2.3 Add comments to service file documenting wrapper script purpose
- [x] 2.4 Ensure script path uses absolute path matching installation location

## 3. Add Actionable Error Messages

- [x] 3.1 Include full module path in "file not found" error message
- [x] 3.2 Add suggestion to run "make" or "make dkms-install" in not-found error
- [x] 3.3 Include permission details in readability error message
- [x] 3.4 Include kernel error output in insmod failure message

## 4. Testing and Validation

- [x] 4.1 Test wrapper script with missing module file (verify exit code 1)
- [x] 4.2 Test wrapper script with unreadable module file (verify exit code 2)
- [x] 4.3 Test wrapper script with pre-existing module loaded (verify unload works)
- [x] 4.4 Test successful module load (verify exit code 0)
- [x] 4.5 Verify error messages appear in journalctl output
- [x] 4.6 Test systemctl status shows meaningful error information

## 5. Documentation

- [x] 5.1 Add exit code reference to README troubleshooting section
- [x] 5.2 Document wrapper script in installation instructions if needed
- [x] 5.3 Add comments in wrapper script explaining each validation step

## 6. Root Cause Fix

- [x] 6.1 Diagnose root cause: missing source files (msi-ec.c)
- [x] 6.2 Fetch source files from upstream repository
- [x] 6.3 Build kernel module (msi-ec.ko)
- [x] 6.4 Update msi-ec-smart-load.sh with enhanced error handling
- [x] 6.5 Deploy updated script to /usr/local/bin/msi-ec-smart-load
- [x] 6.6 Test service startup with module present (verify success)
- [x] 6.7 Test service error handling with module missing (verify exit code 1)
- [x] 6.8 Verify module loads and platform device is accessible
