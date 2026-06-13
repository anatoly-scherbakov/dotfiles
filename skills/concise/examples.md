# Concise — examples and pattern catalog

## Case study: YAML-LD spec examples

**Files:** `examples/basic.yamlld`, `examples/intro.yamlld` (yaml-ld project)

**Document roles:**

- `intro.yamlld` — introductory example in the Abstract; shows dollar convenience syntax, extra context, literals.
- `basic.yamlld` — minimal YAML-LD paired with `examples/generated/basic.jsonld` in the canonicalization section; illustrates `@` quoting.

**Cluster:** Proxima Centauri b planet graph

| Shared element | basic.yamlld | intro.yamlld |
|----------------|--------------|--------------|
| Subject | `dbr:Proxima_Centauri_b` | `dbr:Proxima_Centauri_b` |
| Type | `dbo:Planet` | `dbo:Planet` |
| Star | `dbp:star` → `dbr:Proxima_Centauri` | `dbp:star` → `dbr:Proxima_Centauri` |
| Context | DBpedia prefixes, `dbp:star` as `@id` | Same DBpedia terms plus schema/xsd |

**Overlap type:** Semantic (same RDF triples) + Pedagogical (intro is intentional superset).

**intro.yamlld-only:** `schema:description`, `dbp:discovered`, dollar syntax (`$id`, `$type`).

**Not a cluster:** `basic.jsonld` ↔ `basic.yamlld` — expected cross-format pair; do not flag as unnecessary repetition.

**Recommended actions:**

| Action | Fit |
|--------|-----|
| **Keep** | Valid if pedagogical layering is intentional |
| **Differentiate** | Change subject in one file (e.g. different exoplanet in intro) |
| **Trim** | Remove shared triples from intro if basic remains the canonical minimal graph |
| **Extract shared base** | Shared context fragment referenced by both (if project supports includes) |
| **Merge** | Poor fit — files serve different spec sections and syntax demos |

**Downstream if changed:** `examples/mermaid/*.mmd`, `scripts/generate-examples.sh`, `index.html` `data-include` attributes, `make spec`.

---

## Pattern catalog

### Prose duplication

Two spec sections restate the same definition or constraint in different words.

- **Detect:** Same normative claim, requirement ID, or definition restated.
- **Typical action:** Merge into one authoritative section; replace duplicate with a cross-link.
- **Watch for:** Pedagogical re-explanation in informative vs normative sections — may be intentional.

### Shared config blocks

Identical YAML/JSON context, env vars, or Makefile targets copied across files.

- **Detect:** Same key-value blocks or prefix maps in multiple artifacts.
- **Typical action:** **Extract shared base** — single source included or imported by others.

### Test fixture overlap

Multiple test files embed the same document graph or JSON payload.

- **Detect:** Same subject/properties or byte-identical fixture bodies.
- **Typical action:** **Extract shared base** — shared fixture file loaded by tests.

### Spec example layering

Minimal example early in the doc, richer variant later using the same domain.

- **Detect:** Semantic cluster + different section roles (intro vs reference vs comparison).
- **Typical action:** **Keep** or **Differentiate** — rarely **Merge**.
- **Flag:** Pedagogical overlap; confirm with user before trimming.

### Lexical copy-paste

Near-identical paragraphs across README, spec, and comments.

- **Detect:** High textual similarity, same sentences.
- **Typical action:** **Merge** or single source with link — unless one is user-facing summary and one is normative (then **Keep** with cross-link).
