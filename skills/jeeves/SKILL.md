---
name: jeeves
description: Use when adding, changing, invoking, or explaining `j` tasks, a `jeeves.py` file, a `jeeves` package, or Python modules that exist so Jeeves can import them.
---

# Jeeves tasks

Jeeves discovers tasks by importing the name `jeeves` from the project root. Publish that name as a package. `jeeves/__init__.py` imports each public command from a submodule. The [package guide](https://jeeves.sh/advanced/jeeves-package/) shows the shape.

## Add a task

1. Put the command in a submodule of `jeeves`.
2. Import that command object from `jeeves/__init__.py`.
3. Run `j --help` or the project's command-list test. The public names match the intended tasks, and no helper appears there.

A function becomes `j <name>`. Its docstring is the help text. Parameters and type hints become arguments and options. A `typer.Typer` instance becomes a command group; define its subcommands in that submodule.

Jeeves registers a package attribute when it is a function or a Typer app and its name does not start with `_` or an uppercase letter. Import only the public commands in `__init__.py`.

Keep each task's implementation in the package. A module that exists to back a `j` task is a submodule. `j` is the process entry point, so the package exports callables.

Importing a command with the same name as its submodule replaces that package attribute with the command object. Import the implementation submodule by its module path (`import jeeves.runner`).

## External commands and linting

Invoke external commands from Jeeves tasks with `sh`, using `sh.<program>` for
programs on PATH. Declare `sh` as a project dependency.

When setting up or changing Jeeves tasks, configure Ruff to select `TID251` and
ban `subprocess` with a message directing authors to `sh`. Merge these settings
into the project's existing Ruff configuration and dependency manager. The
banned API setting applies to every file checked with `TID251`; avoid changing
lint behavior for unrelated files by limiting the check or using appropriate
per-file configuration. Run the lint check on the Jeeves task files and verify
that it rejects `import subprocess` and `from subprocess import ...`.

## One module

A root `jeeves.py` fits a project whose tasks are the public functions of that single module. When a task needs another project module, replace the file with the package above.

## Plugins

Ship a reusable command set as an installed plugin in the `jeeves` entry-point group. Use the mount name `__root__` when those commands replace the root app. Follow https://jeeves.sh/plugins/how-to/.
