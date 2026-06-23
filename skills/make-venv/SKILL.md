---
name: make-venv
description: Set up or repair a Python project's local virtual environment using a uv-created .venv, direnv activation, and the project's existing dependency manager. Use when the user asks to create, make, fix, or mirror a project venv, especially for Poetry projects that should not be migrated to uv.
---

# Make Venv

Set up a project-local Python environment without changing the project's packaging strategy.

## Rules

- Prefer a local `.venv` created with `uv venv`.
- Do not migrate an existing project to `uv` metadata unless the user explicitly asks.
- Keep local environment files out of tracked git files unless the user explicitly asks for repo-wide configuration.
- For open source or third-party checkouts, add `.envrc`, `.envrc.local`, and `.venv/` to `.git/info/exclude`.
- Preserve user changes. Check `git status --short` before editing and avoid unrelated tracked-file changes.

## Environment Activation

Create `.envrc` with this content when absent or when the user asks to mirror this setup:

```sh
source .venv/bin/activate

[[ -f .envrc.local ]] && source_env .envrc.local
```

Then run:

```sh
direnv allow <project-path>
```

Verify activation with `direnv export bash` and confirm it points PATH/VIRTUAL_ENV at `<project>/.venv`.

## Dependency Manager Selection

Inspect the project before installing dependencies:

- `pyproject.toml` with `[tool.poetry]`: use Poetry.
- `uv.lock` or `[tool.uv]`: use uv project commands.
- `requirements*.txt`: use `uv pip install -r ...`.
- `setup.py`, `setup.cfg`, or PEP 621 metadata without a lock: use `uv pip install -e .`, adding obvious dev extras only when declared.

When unsure, prefer creating and activating `.venv` first, then stop before changing dependencies if the install command would be a guess.

## Poetry Projects

For Poetry projects:

1. Create or repair `.venv` with `uv venv .venv --python python3`.
2. Confirm the interpreter works — a present `.venv/` directory is not enough. Run `.venv/bin/python --version`, or check that `readlink -f .venv/bin/python` exists. A dead symlink (for example after removing pyenv) means repair the venv before installing dependencies.
3. If `poetry` is not on PATH and `.venv/bin/poetry` does not exist, install Poetry into the venv:

   ```sh
   uv pip install --python .venv/bin/python poetry
   ```

4. Install `pip` into the venv before `poetry install` — `uv venv` does not ship with pip, and Poetry needs it:

   ```sh
   uv pip install --python .venv/bin/python pip
   ```

5. Verify Poetry uses the in-project venv:

   ```sh
   .venv/bin/poetry env info
   ```

6. Install dependencies from the lock file:

   ```sh
   .venv/bin/poetry install --with dev
   ```

   If there is no `dev` group or the command fails because the group is absent, retry with `.venv/bin/poetry install`.

Use `.venv/bin/poetry`, not a global `poetry`, when Poetry was installed into the project venv.

## Verification

At the end, run focused checks:

- `git status --short` to verify no unintended tracked changes.
- `.venv/bin/python --version` — and confirm `readlink -f .venv/bin/python` resolves to an existing interpreter, not a broken symlink.
- Dependency-manager env info when available, such as `.venv/bin/poetry env info`.
- An obvious project CLI or smoke command when one is declared, such as a console script with `--help`.

Report what was created, what installed successfully, and any install/test command that could not be completed.
