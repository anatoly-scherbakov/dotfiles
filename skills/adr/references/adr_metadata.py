"""MkDocs-Macros helpers for an ADR's status banner.

Copy these helpers into the project's MkDocs macro module. ADR frontmatter may
declare a prerequisite as:

    prerequisite:
      title: Use `example.operation()` for input processing
      url: /project/decisions/use-example-operation/

Then render `{{ adr_metadata(date, status, prerequisite) }}` immediately below
the ADR H1. ADRs without a prerequisite keep using
`{{ adr_metadata(date, status) }}`.
"""

from datetime import date as date_type


_ADR_STATUS = {
    'draft': 'Draft',
    'undecided': 'Undecided',
    'decided': 'Decided',
}


_ADR_STATUS_ADMONITION = {
    'draft': 'note',
    'undecided': 'warning',
    'decided': 'success',
}


def _human_date(value):
    if not value:
        return ''
    parsed = date_type.fromisoformat(value) if isinstance(value, str) else value
    return f'{parsed.day} {parsed.strftime("%B %Y")}'


def _adr_metadata_prerequisite(value):
    if not isinstance(value, dict):
        return ''
    title = value.get('title')
    url = value.get('url')
    if not title or not url:
        return ''
    return f'Depends on [{title}]({url})'


def _adr_metadata(date, status, prerequisite=None):
    key = str(status).lower()
    parts = [_ADR_STATUS.get(key, str(status).replace('_', ' ').title())]
    if date:
        parts.append(f':material-calendar-clock: {_human_date(date)}')
    prerequisite_part = _adr_metadata_prerequisite(prerequisite)
    if prerequisite_part:
        parts.append(prerequisite_part)
    return f'!!! {_ADR_STATUS_ADMONITION.get(key, "note")} "{" · ".join(parts)}"\n'


def define_env(env):
    """Register the macro with mkdocs-macros-plugin."""

    @env.macro
    def adr_metadata(date, status, prerequisite=None):
        return _adr_metadata(date, status, prerequisite)
