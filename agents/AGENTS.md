# Global Agent Guidance

## Python Project Environments

- For existing Python projects without `uv` metadata, do not migrate the project
  to `uv` unless explicitly asked. Prefer a local `.venv` created with
  `uv venv` and populated with `uv pip install ...`.
- To auto-activate a project-local virtualenv, use `direnv` with a local
  `.envrc`:

  ```sh
  source .venv/bin/activate

  [[ -f .envrc.local ]] && source_env .envrc.local
  ```

- For open source or third-party checkouts, keep this setup local by adding
  `.envrc`, `.envrc.local`, and `.venv/` to `.git/info/exclude` instead of the
  tracked `.gitignore`, unless the user explicitly wants a repo-wide ignore
  rule.
- After creating or changing `.envrc`, run `direnv allow <project-path>` and
  verify with `direnv export bash` or by checking that `python` resolves to
  `<project>/.venv/bin/python`.

## Browser Validation

- After changing anything web-served, you **must** validate the rendered result
  in **Chromium via Playwright MCP only**.
- **Always** use Playwright MCP (`browser_navigate`, `browser_snapshot`,
  `browser_click`, `browser_wait_for`, `browser_run_code_unsafe`). Never launch
  Google Chrome, `chromium-browser`, or any other browser yourself — including
  for CDP on port 9223.
- **Never** substitute Chrome, naked Playwright, raw HTTP output, HTML/source
  inspection, or `curl` for browser validation.
