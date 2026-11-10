# Rust CLI

Derive the reference from the compiled command. Do not hand-write an arguments
table or the command index.

Read clap's `Command` after the binary is built. Record each public subcommand
as a `cwl:CommandLineTool` and each argument as a `cwl:CommandInputParameter`
with `cwl:inputBinding` and `cwl:CommandLineBinding/prefix`. Skip hidden
commands. Write that record as YAML-LD. Mint a term only for a gap, such as
the rendered usage string or the documentation card.

Keep a second YAML-LD file for facts clap does not know: a card summary, an
icon, a page name, a usage form such as `--query PATH` or `--query -`, and a
description that contains a link. Join the two files on the argument's IRI.

Render both results with a query:

- The index is one card per command, in clap's order.
- Each command page includes that command's arguments, in clap's order.

A required argument is `:material-star:{ title="Required" }`. An optional
argument is `:material-star-outline:{ title="Optional" }`.

Regenerate the model with the project's task. Fail the pull request when the
committed model differs.

On a command page, put a runnable invocation first and its result immediately
after. The arguments table follows that pair. Prose that is not a row of the
model, such as a media-type table, stays in the page.

~~~~markdown
# :material-database-search: sparql

`sparql` sends one query to a SPARQL endpoint and saves the response body in an
output directory.

```sh
vitrify sparql \
  --endpoint https://query.wikidata.org/sparql \
  --query docs/examples/female-persons/query.rq \
  --format csv \
  --to female-persons
```

## :material-format-list-bulleted: Arguments

{{ cli_arguments('sparql') }}
~~~~
