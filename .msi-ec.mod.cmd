savedcmd_msi-ec.mod := printf '%s\n'   msi-ec.o | awk '!x[$$0]++ { print("./"$$0) }' > msi-ec.mod
