# Tailscale on Windows without admin

How to run Tailscale on Windows without admin rights:

This solution is based on the following comment:
https://github.com/tailscale/tailscale/issues/2791#issuecomment-2755455278

## Prerequisites

NOTE: You have to run all the commands in PowerShell.

### For building (optional)

1.  Git (for cloning Tailscale repository).
2.  Docker (Tailscale's Go toolchain is Linux only).

### For running

1.  Windows machine without admin rights.
2.  Compiled Tailscale binaries with patches:
    - `tailscale.exe`
    - `tailscaled.exe`
3.  Some SOCKS proxy helper, like:
    - `connect.exe` (included with Git for Windows)
    - `ncat.exe` (included with Nmap)
    - `nc.exe` (available in some sites)

## Building

1.  Clone Tailscale repository:

    ```pwsh
    git clone https://github.com/tailscale/tailscale.git
    cd tailscale
    ```

2.  Find the latest Tailscale version:
    - Go to this link http://github.com/tailscale/tailscale/releases/latest
    - Take note of the latest tagged version, like: `v1.96.4`

3.  Checkout the latest tag:

    ```pwsh
    git checkout v1.96.4
    ```

4.  Create the output directory:

    ```pwsh
    mkdir dist
    ```

5.  Apply the following patches:
    - `paths/paths.go`

      ```diff
      -		return `\\.\pipe\ProtectedPrefix\Administrators\Tailscale\tailscaled`
      +		return `\\.\pipe\Tailscale\tailscaled`
      ```

      This patch changes the default listen socket, so you don't need to specify `--socket`.

    - `safesocket/pipe_windows.go`

      ```diff
      -var windowsSDDL = "O:BAG:BAD:PAI(A;OICI;GWGR;;;BU)(A;OICI;GWGR;;;SY)"
      +var windowsSDDL = "D:(A;;GA;;;WD)"
      ```

      This patch changes the default listen socket permissions to not require admin rights.

6.  Create a script `build.sh` with this content:

    ```bash
    #!/bin/bash
    set -x
    apk add --no-cache bash curl git
    git config --global --add safe.directory '*'
    TS_USE_TOOLCHAIN=1 GOOS=windows GOARCH=amd64 ./build_dist.sh -o dist/tailscale.exe -v ./cmd/tailscale
    TS_USE_TOOLCHAIN=1 GOOS=windows GOARCH=amd64 ./build_dist.sh -o dist/tailscaled.exe -v ./cmd/tailscaled
    ```

7.  Perform the build in Alpine container:

    ```pwsh
    docker run -it --rm -v $PWD:/app -w /app alpine sh build.sh
    ```

8.  Move the `dist` folder to a location you will remember.

    It should contain the following files:
    - `tailscale.exe` (the Tailscale client binary)
    - `tailscaled.exe` (the Tailscale daemon binary)

9.  For convenience, also copy the `connect.exe` binary or similar to that folder.

## Running

Change to the directory where you copied the files.

### Start the daemon

- **This should be done once at boot, before using any Tailscale command.**
- You might find it useful adding this command to a `.bat` file or some service.
- You can change the `statedir` and the `socks5-server` as you see it fits.
- Usually `C:\ProgramData\Tailscale` does not require admin rights.

```pwsh
tailscaled.exe --no-logs-no-support --port=0 --tun=userspace-networking --statedir=C:\ProgramData\Tailscale --socks5-server=localhost:1080
```

### Tailscale login

- **This should be done once per account, it logins you with Tailscale.**
- Note that `unattended` flag is required, it won't let you connect without it.
- `auth-key` and other flags are up to you, it's how you login to Tailscale.
- You can omit `auth-key` in order to use web-based login as usual.

```pwsh
tailscale.exe up --unattended --accept-dns=false --auth-key=xxxxxxxx
```

### Tailscale status

This should show you the Tailscale status.

```pwsh
tailscale.exe status
```

## Client config

- When Tailscale runs with admin rights, it creates a network adapter that handles networking.
- Since we're running without admin rights (userspace), Tailscale exposes a SOCKS5 proxy instead.
- So we need to configure our clients to use that SOCKS proxy in order to reach Tailscale IPs.

### SSH (Windows)

Create the `.ssh\config` file in your user folder.
Replace the path to `connect.exe` and the SOCKS5 proxy address if you changed it.

```plain
Host my.ssh.host
    ProxyCommand path\to\connect.exe -S 127.0.0.1:1080 %h %p
```
