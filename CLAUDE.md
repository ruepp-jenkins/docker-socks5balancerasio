# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A CI-only wrapper that builds and pushes multi-arch Docker images of the upstream project https://github.com/Socks5Balancer/Socks5BalancerAsio. It contains no application code and no Dockerfile: the upstream repo's own Dockerfile is used. There are no tests, linter, or local build setup.

## How the pipeline works

- `Jenkinsfile` runs on the `oracle_docker` agent. `URLTrigger` polls every 4 hours (`0 H/4 * * *`) and starts a build when any of these change: the `alpine:3` or `node:lts` Docker Hub `last_updated`, or the latest upstream `master` commit date. Base-image triggers exist so images are rebuilt when the upstream Dockerfile's base images update.
- Stages: clean workspace → checkout this repo → `scripts/start.sh`. A Discord notification is sent in `post.always` (uses the `DISCORD_WEBHOOK` env var provided by Jenkins).
- `scripts/start.sh` orchestrates: `docker_initialize.sh` (Docker Hub login using `DOCKER_USERNAME`/`DOCKER_API_PASSWORD`, installs and creates a buildx builder) → `git.sh` (clones upstream into `./repo`) → `docker buildx build` of `./repo/` for `linux/amd64,linux/ppc64le,linux/arm64/v8` with `--pull --push`.
- Tagging depends on `BRANCH_NAME`: `main`/`master` pushes `${IMAGE_FULLNAME}:latest` and `:YYYYMMDD`; any other branch pushes only `${IMAGE_FULLNAME}-test:${BRANCH_NAME}`.

## Notes

- The scripts rely on env vars supplied by Jenkins (`IMAGE_FULLNAME`, `BRANCH_NAME`, `DOCKER_API_PASSWORD`, `DOCKER_USERNAME`); running them locally pushes to the real registry, so don't run `start.sh` casually.
- The Jenkinsfile does `chmod +x scripts/*.sh` at build time, and scripts are invoked with paths relative to the repo root.
- If upstream's Dockerfile changes its base images, update the `URLTrigger` entries in the `Jenkinsfile` accordingly.
