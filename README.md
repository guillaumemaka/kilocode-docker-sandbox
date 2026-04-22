# kilocode

A Docker image for running [Kilo](https://kilo.ai) inside a [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) (`sbx`).

```
docker.io/guillaumemaka/kilocode
```

## What this is

`docker/sandbox-templates:opencode` — the official base image used by `sbx` — does not include the AWS CLI or any AWS credential handling. This image adds:

- **An entrypoint** that bridges a known `sbx` quirk: `sbx` mounts host directories at their original host path (e.g. `/Users/alice/.aws`) rather than at the container user's `$HOME` (`/home/agent`). The entrypoint detects those mounts and symlinks them into `$HOME` before kilocode starts.

Everything else — kilocode itself, Node.js, git — comes from the upstream `docker/sandbox-templates:kilocode` base image.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for building)
- [`sbx`](https://docs.docker.com/ai/sandboxes/) — Docker Sandboxes CLI

## Quick start

### Run in a sandbox

```bash
cd ~/my-project
sbx run --template guillaumemaka/kilocode kilocode . ~/.config/kilo:ro
```

`sbx` pulls the image from Docker Hub on first use. On subsequent runs for the same project, omit `--template` to reuse the existing sandbox:

```bash
sbx run kilocde-my-project
```

## How credentials work

`sbx` mounts host directories at their literal host path inside the sandbox VM. For example, `~/.aws` on a Mac becomes `/Users/alice/.config/kilo` inside the container — not `/home/agent/.config/kilo`.

The entrypoint (`entrypoint.sh`) resolves this automatically:

1. It parses `/proc/mounts` for `virtiofs` entries (the filesystem type used by `sbx`) to find where `~/.config/kilo` were mounted.
2. It creates symlinks from `/home/agent/.config/kilo` to those mount points.
3. It then hands off to `kilocode`.

## Managing sandboxes

```bash
# List all sandboxes
sbx ls

# Stop a sandbox without removing it
sbx stop kilocode-my-project

# Remove a sandbox
sbx rm kilocode-my-project
```

## Building the image yourself

```bash
# Build locally (current architecture only)
./build.sh

# Build multi-arch and push to Docker Hub
./build.sh --push

# Build multi-arch, push, and also tag a specific version
./build.sh --push --tag 1.2.3
```

`--push` requires that you are logged in to Docker Hub (`docker login`) and that you update the `IMAGE` variable in `build.sh` to point to your own repository.

## Automated releases via GitHub Actions

The included `.github/workflows/release.yml` workflow builds and pushes a multi-arch image automatically:

- **On a git tag** (`v*`): pushes `latest` and a version tag derived from the tag name (e.g. `git tag v1.2.3` → `1.2.3` and `latest`).
- **On manual trigger** (`workflow_dispatch`): pushes `latest` and an optional additional tag.

### Setup

Add the following secrets to your GitHub repository (**Settings → Secrets and variables → Actions**):

| Secret               | Value                                                                                           |
| -------------------- | ----------------------------------------------------------------------------------------------- |
| `DOCKERHUB_USERNAME` | Your Docker Hub username                                                                        |
| `DOCKERHUB_TOKEN`    | A Docker Hub [access token](https://hub.docker.com/settings/security) with `Read & Write` scope |

Then update the `IMAGE` variable at the top of `.github/workflows/release.yml` to match your Docker Hub repository.

### Releasing a new version

```bash
git tag v1.2.3
git push origin v1.2.3
```

The workflow pushes `thath/kilocode-bedrock:1.2.3` and `thath/kilocode-bedrock:latest`.

## Repository structure

```
.
├── Dockerfile             # Extends docker/sandbox-templates:kilocode with AWS CLI
├── entrypoint.sh          # Symlinks host-mounted dirs into $HOME at startup
├── build.sh               # Local build and Docker Hub push script
├── .dockerignore          # Keeps build context minimal
└── .github/
    └── workflows/
        └── release.yml    # Automated multi-arch build and push on git tags
```

## Related

- [kilo.ai](https://kilo.ai) — kilo documentation
- [docker/sandbox-templates](https://hub.docker.com/r/docker/sandbox-templates) — upstream base images
- [Docker Sandbox docs](https://docs.docker.com/sandbox/) — `sbx` CLI documentation
- [Inspired By docker-sandbox-opencode-bedrock
](https://github.com/travishathaway/docker-sandbox-opencode-bedrock)
