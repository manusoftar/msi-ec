## Context

The msi-ec-custom.service is a systemd oneshot service that loads a custom kernel module (`msi-ec.ko`) to enable MSI laptop embedded controller features. Currently, the service uses a direct `insmod` command without validation or error handling, leading to silent failures when:
- The module file doesn't exist (not built)
- Path is incorrect
- Insufficient permissions
- Kernel compatibility issues

The service runs at boot (Type=oneshot, RemainAfterExit=yes) and failures only show as "status=1/FAILURE" in journalctl, making diagnosis difficult.

## Goals / Non-Goals

**Goals:**
- Implement pre-flight validation before attempting module load
- Add detailed error logging to journalctl for common failure scenarios
- Make the service more resilient to expected failure conditions
- Provide actionable error messages to users

**Non-Goals:**
- Automatic module building (users should follow installation docs)
- GUI error notifications (command-line/journalctl only)
- Fixing underlying kernel compatibility issues
- Replacing systemd with alternative service management

## Decisions

### Decision 1: Wrapper Script Approach
Use a wrapper shell script instead of direct `insmod` in the service ExecStart.

**Rationale:** Shell scripts allow complex logic (file checks, conditional logging, multiple failure modes) without requiring systemd service syntax gymnastics. This matches the existing pattern used by msi-fan-daemon scripts in the repo.

**Alternative Considered:** Multiple ExecStartPre conditions - rejected because systemd's `-` prefix only suppresses failure, doesn't enable custom error messages.

### Decision 2: Standardized Error Codes
Define specific exit codes for different failure scenarios:
- 1: Module file not found
- 2: Module file not readable (permissions)
- 3: insmod failed (kernel/compatibility)
- 0: Success

**Rationale:** Allows systemd and users to distinguish between "module not built yet" vs "kernel rejected module". Exit codes visible in `systemctl status`.

**Alternative Considered:** All errors exit 1 - rejected because it loses diagnostic information.

### Decision 3: Check Order
1. Verify .ko file exists at expected path
2. Verify file is readable
3. Attempt module load
4. Log specific error with journalctl-visible message

**Rationale:** Fail fast on simple issues (missing file) before attempting kernel operations. Each step provides progressively more specific diagnostics.

### Decision 4: Logging Strategy
Use `echo` to stderr for error messages (captured by systemd journal) rather than separate log files.

**Rationale:** Keeps logs centralized in journalctl, follows systemd best practices. Users already check `systemctl status` and `journalctl -u` for service issues.

**Alternative Considered:** Custom log file in /var/log - rejected because it fragments logging and requires log rotation setup.

## Risks / Trade-offs

**Risk:** Wrapper script adds complexity compared to direct insmod
→ **Mitigation:** Keep script simple (<50 lines), add comments, follow existing project patterns

**Risk:** Script path hardcoded in service file could break if repository moves
→ **Mitigation:** Use absolute path consistent with installation docs, document in comments

**Risk:** More verbose logging could expose sensitive system information
→ **Mitigation:** Log only non-sensitive info (file paths, error codes), no kernel addresses or user data

**Trade-off:** Exit codes improve debugging but require documentation
→ Document in script comments and README

**Trade-off:** Pre-flight checks add minimal startup delay (~10ms)
→ Acceptable for a boot-time oneshot service, improves reliability significantly
