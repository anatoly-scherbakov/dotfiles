{# template: material-mutually-exclusive-tabs

When to use: pick exactly one from mutually exclusive options.

Frontmatter: include hide: [toc] (MkDocs Material).

Rejected alternatives: optional Context subsection (any heading; bullets or table). Rejected options also appear in Decision as :x: tabs with a one-line reason.

Tab ordering: chosen first, undecided in the middle, rejected last. If there is no chosen alternative yet, undecided come first, then rejected.

Icons: :white_check_mark: (chosen), :question: (undecided), :x: (rejected). Kept tabs include a Pro/Contra grid.

When a decision lands: change frontmatter status: undecided → status: decided; flip the chosen tab icon from :question: to :white_check_mark:; apply R29 for title/H1.

Stage 2 — if excluded: becomes a :x: tab with the reason as its body; optionally a bullet or table row under any Context subheading.

Stage 2 — if keep or undecided: ask for one-line Pro and one-line Contra; mark :question: for now.

Stage 2 — after all options: ask "ready to pick one?"; if yes, the user names the chosen option → :white_check_mark:; other kept options stay :question:; if no, all kept options stay :question: and status stays undecided. Never decide for the user.
#}
---
title: <Verb-leading title>
status: undecided
date: <YYYY-MM-DD, today>
author: <Author name>
tags: [decision]
hide: [toc]
---

# <Title>

## :material-text-box-outline: Context

<Context paragraph(s).>

### <Optional rejected-alternatives heading>

- <Rejected alt 1 — optional>

## :material-arrow-decision-outline: Decision

=== ":white_check_mark: <Chosen alternative>"

    <One-paragraph rationale.>

    <div class="grid" markdown>
    <div markdown>
    #### Pro
    - <bullet>
    </div>

    <div markdown>
    #### Contra
    - <bullet>
    </div>
    </div>

=== ":question: <Undecided alternative>"

    <Description.>

    <div class="grid" markdown>
    <div markdown>
    #### Pro
    - <bullet>
    </div>

    <div markdown>
    #### Contra
    - <bullet>
    </div>
    </div>

=== ":x: <Rejected alternative>"

    <One-line reason for rejection.>

## :material-arrow-right-bold-outline: Consequences

- <Bullet>

#### Implementation Steps

- [ ] <Step>
- [ ] <Step>
