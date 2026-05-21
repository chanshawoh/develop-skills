---
name: macos-local-runtime
description: Use when running, configuring, or troubleshooting local development commands on the user's macOS machine, especially Java, Node.js, Python, package managers, version managers, or build/test tools. Prefer existing ServBay language packages for Java and Node when present, prefer uv for Python, fall back conservatively to Homebrew or system tools only when needed, and avoid unnecessary installs, large downloads, or environment bloat.
---

# macOS Local Runtime

Use this skill before running local development commands that depend on Java, Node.js, Python, package managers, version managers, build tools, or language runtimes on macOS.

The goal is to use the user's existing local runtimes first, especially ServBay and uv, and to avoid bloating the system with duplicate packages.

## Priorities

1. Prefer project-pinned tools and versions when the repository declares them.
   - Check files such as `.tool-versions`, `.node-version`, `.nvmrc`, `.java-version`, `.sdkmanrc`, `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `pom.xml`, `gradle.properties`, `pyproject.toml`, `uv.lock`, and `requirements*.txt`.
   - Do not override explicit project requirements unless they are unavailable locally.

2. Prefer existing ServBay language packages for Java and Node.js.
   - Check `/Applications/ServBay/package/` before installing or using a global package manager.
   - ServBay may contain multiple versions of the same language. Pick the project-required version when known; otherwise pick a stable, compatible version already installed.
   - Do not assume a single fixed path. Discover with commands such as:

```bash
find /Applications/ServBay/package -maxdepth 3 -type d \( -iname 'openjdk*' -o -iname 'node*' \) 2>/dev/null
```

3. Prefer `uv` for Python.
   - Use `uv run`, `uv sync`, `uv python`, and `uvx` when the project supports Python workflows.
   - Prefer project-local virtual environments such as `.venv` managed by uv.
   - Fall back to Homebrew Python only when uv is missing or cannot satisfy the project requirement.

4. Use Homebrew conservatively.
   - Treat `brew install` as a fallback, not the first move.
   - Before installing, check whether the tool already exists via project-local binaries, ServBay, uv, Homebrew, or the system path.
   - Avoid installing large toolchains or duplicate runtime versions unless the task clearly requires them.

## Java

When Java is needed:

1. Identify the required Java version from the project.
2. Check ServBay first, for example `/Applications/ServBay/package/openjdk/11`, while allowing other installed versions.
3. For a command that should use ServBay Java, set `JAVA_HOME` and prepend `bin` only for that command or shell session:

```bash
export JAVA_HOME="/Applications/ServBay/package/openjdk/11"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

4. If the exact version is not present, choose the nearest compatible installed ServBay JDK when safe.
5. Use Homebrew or another installer only when no suitable local JDK exists and the task cannot proceed without it.

## Node.js

When Node.js is needed:

1. Identify the required Node version from project metadata.
2. Check ServBay Node packages before `nvm`, `fnm`, `volta`, or Homebrew.
3. If a suitable ServBay Node exists, prepend its `bin` directory for the command or session:

```bash
export PATH="/Applications/ServBay/package/node/<version>/bin:$PATH"
node -v
```

4. Prefer the package manager indicated by lockfiles:
   - `pnpm-lock.yaml` -> `pnpm`
   - `yarn.lock` -> `yarn`
   - `package-lock.json` -> `npm`
   - `bun.lock` or `bun.lockb` -> `bun`, if already available
5. Avoid global npm installs when `npx`, `pnpm dlx`, `corepack`, or project-local scripts can do the job.

## Python

When Python is needed:

1. Use uv first when available:

```bash
uv --version
uv sync
uv run python --version
```

2. Use project metadata to choose commands:
   - `pyproject.toml` or `uv.lock`: prefer `uv sync` and `uv run`.
   - `requirements.txt`: prefer `uv pip install -r requirements.txt` into a local `.venv` when installation is needed.
   - One-off tools: prefer `uvx <tool>` instead of global installs.
3. Keep Python environments local to the project. Avoid global `pip install`.
4. Fall back to Homebrew Python only when uv is unavailable or incompatible with the task.

## Install Discipline

Before installing anything:

1. Check whether the command already exists:

```bash
command -v <tool>
```

2. Check known local managers and package locations:
   - `/Applications/ServBay/package/`
   - `uv`
   - project-local `node_modules/.bin`
   - Homebrew via `brew list` or `brew --prefix`
   - system tools in `/usr/bin` and `/usr/local/bin` or `/opt/homebrew/bin`
3. Prefer temporary, project-local, or command-scoped use over global installation.
4. Explain any install decision with the reason, expected size or scope when known, and why existing tools are insufficient.

## Command Style

- Use command-scoped environment changes when possible, so the user's shell profile is not permanently modified.
- Do not edit shell startup files such as `.zshrc`, `.zprofile`, or `.bash_profile` unless explicitly requested.
- Do not delete existing runtimes, caches, or package directories unless explicitly requested.
- Keep changes reversible and local to the current project.
- After selecting a runtime, verify with the relevant version command before running build, test, or install steps.
