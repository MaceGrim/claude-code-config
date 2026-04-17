Open the current working directory in Windows Explorer.

Convert the current working directory from its WSL path to a Windows path using `wslpath -w`, then open it with `explorer.exe`.

If the user provides an argument like `$ARGUMENTS`, open that path instead of the current directory. The argument could be a WSL path or a Windows path - handle both.

Run the command and confirm the folder was opened. Note that explorer.exe may return exit code 1 on WSL even when it succeeds - this is normal.
