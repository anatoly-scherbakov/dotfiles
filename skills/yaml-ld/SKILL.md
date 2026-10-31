---
name: yaml-ld
description: Author or edit YAML-LD files, JSON-LD contexts encoded as YAML, and linked-data Markdown frontmatter. Apply YAML 1.2 semantics, dollar-convenience aliases, quoting conventions, and syntax and expansion checks.
---

# Author YAML-LD

Use these rules for standalone `.yamlld` files, YAML context documents, and
YAML-LD frontmatter. Use `semantify` when formalizing a Markdown document's prose.

## Syntax and parsing

- Use YAML 1.2 semantics. Use a YAML 1.2 parser for data loading and validation.
  In Python, use `ruamel.yaml.YAML(typ="safe", pure=True)` for plain data.
  Use its round-trip mode when preserving existing comments and scalar styles.
  Avoid direct PyYAML use; it applies YAML 1.1 implicit typing.
- Quote scalars only when needed to preserve their meaning or make valid YAML.
  Use double quotes when quoting is required, including `"@context"` and raw
  JSON-LD keywords. Leave ordinary URLs, CURIEs, and unambiguous strings plain.
- In the graph body, prefer the dollar-convenience context
  `https://json-ld.org/contexts/dollar-convenience.jsonld` and aliases such as
  `$id`, `$type`, and `$included`. This also applies to nested node objects.
- Keep `"@context"` as written: the dollar context does not define `$context`.
  Inside context definitions, use standard JSON-LD keyword keys and values,
  such as `"@id"`, `"@type": "@id"`, and `"@container": "@set"`.
- Preserve the consumer's context-loading requirements. For offline consumers,
  register the dollar context locally through their supported mechanism.
  A context URL alone does not guarantee that the consumer can resolve it.

## Lint and validate

Use the project's existing lint task and configuration. When adding a YAML-LD
quote check, merge these settings into its yamllint configuration:

```yaml
yaml-files:
  - "*.yamlld"
rules:
  quoted-strings:
    quote-type: double
    required: only-when-needed
    check-keys: true
```

Preserve existing file patterns and rules when merging. Explicitly include
`*.yamlld`: yamllint's default directory discovery omits that extension.
Run `yamllint --list-files <directory>` to verify discovery, then
`yamllint --strict <directory>` to check it. Use `-c <config>` when necessary.

For Markdown, lint only the extracted YAML frontmatter through standard input:
`yamllint --strict -c <config> -`. Keep the Markdown body out of that check.

Yamllint checks source style and uses PyYAML internally. Validate data semantics
with a YAML 1.2 parser and expand the document with the project's JSON-LD/YAML-LD
processor. Verify that literals and IRI-valued properties expand as intended.
Keep context lookup consistent with the target consumer during expansion.

## References

- [ruamel.yaml parsing modes](https://yaml.dev/doc/ruamel.yaml/basicuse/)
- [yamllint configuration and discovery](https://yamllint.readthedocs.io/en/stable/configuration.html)
- [yamllint quoting rule](https://yamllint.readthedocs.io/en/stable/rules.html#module-yamllint.rules.quoted_strings)
