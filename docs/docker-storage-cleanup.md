# Docker storage cleanup for OrbStack

This maintenance job keeps local Docker storage from growing without bounds. It
uses Docker's own prune commands and macOS `launchd`; it does not depend on
Codex or any remote scheduler.

## Components

| Component | Responsibility |
| --- | --- |
| `scripts/docker-storage-cleanup` | Validates the target and performs or previews cleanup. |
| `install/launchagents/com.txema.docker-storage-cleanup.plist` | Runs cleanup when loaded and every 259,200 seconds (72 hours). |
| `install/docker-storage-cleanup.sh` | Installs, verifies, reports, or removes the local job. |

Installation creates these two symlinks:

- `~/.local/bin/docker-storage-cleanup` → the repository script.
- `~/Library/LaunchAgents/com.txema.docker-storage-cleanup.plist` → the repository LaunchAgent.

The stable executable link means the LaunchAgent does not depend on a macOS
username or on expanding the repository path inside the plist.

## Cleanup policy

An actual run performs the following operations in order:

1. Stops the known Kamal local builders if they still target OrbStack.
2. Removes all cache from the verified OrbStack BuildKit builder.
3. Removes Docker images not referenced by any container.
4. Removes unused anonymous volumes.

It deliberately preserves:

- named volumes, including database volumes;
- stopped containers and their metadata;
- images referenced by running or stopped containers;
- all Docker data when the active engine cannot be proven to be OrbStack.

The script never starts OrbStack. If OrbStack or Docker is stopped, the
scheduled run logs a skip and exits successfully.

## Safety checks

Before any mutation, the script requires all of the following:

- an explicit `--force` execution mode;
- the active Docker context name to be `orbstack`;
- that context to point to the current user's OrbStack Unix socket;
- no `DOCKER_HOST` or `BUILDX_BUILDER` override;
- a Docker builder named `orbstack` using the `docker` driver and the verified
  context;
- any Kamal builder it stops to use the `docker-container` driver and the same
  context;
- an exclusive macOS `lockf` lock, preventing overlapping cleanups.

Use `--dry-run` to exercise the same validation and display the planned Docker
commands without stopping builders or pruning data.

## Automatic workstation installation

The standard bootstrap path installs the task automatically:

```text
install.sh
  -> install/installer.sh
     -> install/docker-storage-cleanup.sh install
```

The component installer validates the executable and plist, creates the stable
links, reloads the LaunchAgent, enables it, and verifies that `launchctl` can
read the registered job. A bootstrap failure is returned to the main installer
instead of being silently ignored. Installation refuses to replace regular
files, foreign symlinks, or dangling symlinks at either managed path.

OrbStack itself is a prerequisite and is not installed by this component. It is
safe to install the task first: scheduled runs skip cleanly until the OrbStack
Docker engine is available. `jq` is a runtime dependency and is included in the
repository Brewfile.

To install or reload only this component:

```bash
./install/docker-storage-cleanup.sh install
```

Installation is idempotent, so running it again safely reloads the same task.

## Operation and verification

Preview a cleanup:

```bash
docker-storage-cleanup --dry-run
```

Run it immediately:

```bash
docker-storage-cleanup --force
```

Inspect the registered schedule and last exit code:

```bash
./install/docker-storage-cleanup.sh status
```

Useful fields in the `launchctl` output are:

- `state`: normally `not running` between executions;
- `last exit code`: `0` after a successful cleanup or safe skip;
- `run interval`: `259200 seconds`.

Inspect current Docker storage:

```bash
docker system df
```

Logs are appended to:

```text
~/Library/Logs/com.txema.docker-storage-cleanup.log
~/Library/Logs/com.txema.docker-storage-cleanup.err.log
```

Docker or validation failures stop the run before later prune operations. A
failed process releases the advisory lock automatically, allowing the next
scheduled or manual run to retry.

## Native BuildKit garbage collection

The 72-hour task is independent from BuildKit's own periodic garbage collector.
On a constrained workstation, OrbStack's Docker engine can also use this policy
in `~/.orbstack/config/docker.json`:

```json
{
  "builder": {
    "gc": {
      "enabled": true,
      "policy": [
        {
          "all": true,
          "maxUsedSpace": "4GB",
          "reservedSpace": "1GB"
        }
      ]
    }
  }
}
```

Restart OrbStack after changing that file, then verify the active policy:

```bash
docker buildx inspect orbstack
```

The expected GC policy reports `Reserved Space: 1GiB` and
`Max Used Space: 4GiB`.

## Uninstall

The complete dotfiles uninstaller removes the job automatically. To remove only
this component:

```bash
./install/docker-storage-cleanup.sh uninstall
```

Uninstall unloads the LaunchAgent and removes only symlinks owned by this
installer. Existing logs and Docker data are preserved.

## Tests

Run the cleanup behavior and installation lifecycle suites with:

```bash
zsh tests/docker-storage-cleanup.zsh
zsh tests/docker-storage-cleanup-install.zsh
```
