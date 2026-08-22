import datetime
import os
import re
import tempfile
from concurrent.futures import ProcessPoolExecutor, as_completed as _as_completed
from pathlib import Path

import sh
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TimeRemainingColumn

TEMPLATE = """
---
date: {date}
time: {time}
title: {title}
---

Write something here.
"""

DOCS = Path.home() / 'Documents'
SYNOLOGY = Path.home() / 'synology'
BACKUP_EXCLUDES = (
    '.git',
    '.DS_Store',
    '.idea',
    '.vscode',
    '.env',
    '.env.*',
    '.mypy_cache',
    '.pytest_cache',
    '__pycache__',
    '.ruff_cache',
    '.fingerprint',
    '*.pyc',
    'node_modules',
    'mkdocs-material-insiders',
    '.venv',
)
console = Console()

DATED_ENTRY = re.compile(r'^(\d{4}-\d{2}-\d{2})(?:\.|$)')
MONTH_DIRECTORY = re.compile(r'^(\d{4})-(\d{2})$')

SYNC_SOURCES = (
    (DOCS, SYNOLOGY / 'home' / 'Documents'),
    (Path.home() / 'projects', SYNOLOGY / 'home' / 'projects'),
)


def new(name: str):
    """Create a new document."""
    today = datetime.date.today()
    file_name = f'{today}.{name}.md'
    path = DOCS / file_name

    if path.exists():
        raise FileExistsError(path)

    path.write_text(
        TEMPLATE.format(
            date=today,
            time=datetime.datetime.now().time().strftime('%H:%M'),
            title=name.capitalize(),
        ).lstrip()
    )

    sh.typora(file_name, _fg=True)


def _year_directory(root: Path, year: int, today: datetime.date) -> Path:
    """Return the directory which owns an archived year."""
    if year // 10 < today.year // 10:
        return root / f'{year // 10 * 10}x' / str(year)
    return root / str(year)


def _move(source: Path, destination: Path, dry_run: bool) -> bool:
    """Move source to destination without overwriting an existing entry."""
    if destination.exists() or destination.is_symlink():
        console.print(f'[yellow]Skipped (destination exists):[/yellow] {source.name}')
        return False

    if not dry_run:
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.rename(destination)
    return True


def organize(dry_run: bool = False):
    """Archive dated entries from concluded months.

    Entries from the current month and future dates stay in the document root.
    Pass --dry-run to review the moves without changing anything.
    """
    _organize(DOCS, datetime.date.today(), dry_run)


def sync(dry_run: bool = False):
    """Organize Documents and mirror Documents and projects to Synology."""
    failed = False

    try:
        organize(dry_run=dry_run)
    except Exception as error:
        failed = True
        console.print(f'[yellow]Documents organization failed: {error}[/yellow]')

    if not dry_run:
        healthcheck()
    elif not SYNOLOGY.is_mount():
        raise RuntimeError(f'Synology is not mounted at {SYNOLOGY}')

    for source, destination in SYNC_SOURCES:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8') as excludes:
            excludes.writelines(
                f'{pattern}\n' for pattern in _symlink_excludes(source, destination)
            )
            excludes.flush()

            arguments = _rsync_arguments(dry_run=dry_run)
            arguments.extend((f'--exclude-from={excludes.name}', f'{source}/', f'{destination}/'))

            console.print(f'[cyan]Syncing {source}[/cyan]')
            try:
                sh.rsync(*arguments, _fg=True)
            except sh.ErrorReturnCode:
                failed = True
                console.print(f'[yellow]Sync failed: {source}[/yellow]')

    if failed:
        raise RuntimeError('One or more synchronization steps failed')


def healthcheck():
    """Confirm that the mounted Synology destinations accept a small write."""
    if not SYNOLOGY.is_mount():
        raise RuntimeError(f'Synology is not mounted at {SYNOLOGY}')

    for _, destination in SYNC_SOURCES:
        if not destination.is_dir():
            raise RuntimeError(f'Synology destination is unavailable: {destination}')

        probe = destination / f'.backup-healthcheck-{os.getpid()}'
        descriptor = os.open(probe, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        try:
            os.fsync(descriptor)
        finally:
            os.close(descriptor)
        probe.unlink()


def _rsync_arguments(
    dry_run: bool = False,
    checksum: bool = False,
    itemize_changes: bool = False,
    stats: bool = False,
) -> list[str]:
    """Return rsync options shared by mirroring and verification."""
    arguments = [
        '-avJ',
        '--delete-delay',
        '--no-links',
        '--no-owner',
        '--no-group',
        '--no-perms',
        *(f'--exclude={pattern}' for pattern in BACKUP_EXCLUDES),
    ]
    if dry_run:
        arguments.append('--dry-run')
    if checksum:
        arguments.append('--checksum')
    if itemize_changes:
        arguments.append('--itemize-changes')
    if stats:
        arguments.append('--stats')
    return arguments


def _symlink_excludes(*roots: Path) -> list[str]:
    """Return rsync patterns that ignore symlinks and preserve their backups."""
    patterns = set()
    for root in roots:
        for directory, subdirectories, files in os.walk(root, followlinks=False):
            for name in (*subdirectories, *files):
                path = Path(directory) / name
                if path.is_symlink():
                    patterns.add(f'/{path.relative_to(root)}')
    return sorted(patterns)


def _organize(root: Path, today: datetime.date, dry_run: bool):
    """Apply the archival rules to root for the supplied date."""
    current_month = today.replace(day=1)
    archived_entries = 0
    archived_months = 0
    invalid_dates = []

    for entry in list(root.iterdir()):
        match = DATED_ENTRY.match(entry.name)
        if not match:
            continue

        try:
            entry_date = datetime.date.fromisoformat(match.group(1))
        except ValueError:
            invalid_dates.append(entry.name)
            continue

        if entry_date >= current_month:
            continue

        if entry_date.year == today.year:
            destination_directory = root / entry_date.strftime('%Y-%m')
        else:
            destination_directory = (
                _year_directory(root, entry_date.year, today)
                / entry_date.strftime('%Y-%m')
            )
        destination = destination_directory / entry.name
        if _move(entry, destination, dry_run):
            archived_entries += 1
            console.print(f'[cyan]{entry.name}[/cyan] → {destination.relative_to(root)}')

    for entry in list(root.iterdir()):
        if not entry.is_dir() or entry.is_symlink():
            continue
        match = MONTH_DIRECTORY.match(entry.name)
        if not match:
            continue

        year, month = map(int, match.groups())
        try:
            datetime.date(year, month, 1)
        except ValueError:
            continue
        if year >= today.year:
            continue

        destination = _year_directory(root, year, today) / entry.name
        if _move(entry, destination, dry_run):
            archived_months += 1
            console.print(f'[cyan]{entry.name}[/cyan] → {destination.relative_to(root)}')

    action = 'Would archive' if dry_run else 'Archived'
    console.print(
        f'[bold green]{action} {archived_entries} dated entries and '
        f'{archived_months} month directories.[/bold green]'
    )
    if invalid_dates:
        console.print(
            '[yellow]Invalid date prefixes left in place:[/yellow] '
            + ', '.join(invalid_dates)
        )


def update_topics():
    """Update topic directories by symlinking relevant files."""
    # Define categories with their patterns
    categories = {
        'ophtalmology/mntk': lambda name: 'mntk' in name.lower(),
        'ophtalmology/pigmalion': lambda name: 'pigmalion' in name.lower() and 'ophtalmologist' in name.lower(),
        'ophtalmology/altai': lambda name: (
            ('ophtalmolog' in name.lower() or 'detachment' in name.lower())
            and ('ust-koksa' in name.lower() or 'gorno-altaysk' in name.lower())
        ),
        'ophtalmology/dacryocystorhinostomy': lambda name: (
            'dacryocyst' in name.lower() or 'dacryorhinocyst' in name.lower()
        ),
        'ophtalmology/niigb': lambda name: 'niigb' in name.lower(),
        'ophtalmology/malayan': lambda name: 'malayan' in name.lower(),
        'construction/links': lambda name: 'soc69' in name.lower()  or 'amazonit' in name.lower() or 'leroy' in name.lower() or 'merlin' in name.lower() or 'социалистический' in name.lower(),
    }
    
    # Process each category
    for category, pattern_func in categories.items():
        target_dir = DOCS / 'topics' / category
        
        if target_dir.exists():
            # Remove all existing symlinks
            for item in target_dir.iterdir():
                if item.is_symlink():
                    item.unlink()
        else:
            target_dir.mkdir(parents=True)
        
        # Traverse all date-bound directories and find matching PDF files
        for item in DOCS.iterdir():
            if item.is_dir():
                # Find all PDF files recursively
                for pdf_file in item.rglob('*.pdf'):
                    if pattern_func(pdf_file.name):
                        # Create a symlink in the target directory
                        symlink_path = target_dir / pdf_file.name
                        if not symlink_path.exists():
                            symlink_path.symlink_to(pdf_file.absolute())


def _convert_pdf_to_images(pdf_path, output_prefix):
    """Convert a single PDF to images. Used by topics_to_images."""
    try:
        sh.pdftoppm(
            '-png',
            '-scale-to', '1500',
            str(pdf_path),
            str(output_prefix)
        )
        return True, pdf_path.name
    except Exception as e:
        return False, f"{pdf_path.name}: {e}"


def topics_to_images():
    """Convert all PDF files in topics/ophtalmology to images."""
    ophtalmology_dir = DOCS / 'topics' / 'ophtalmology'
    extracts_dir = ophtalmology_dir / 'extracts'
    
    # Create extracts directory
    extracts_dir.mkdir(parents=True, exist_ok=True)
    
    # Collect all PDF files first
    pdf_tasks = []
    for category_dir in ophtalmology_dir.iterdir():
        if not category_dir.is_dir() or category_dir.name == 'extracts':
            continue
        
        for symlink in category_dir.iterdir():
            if symlink.is_symlink() and symlink.suffix == '.pdf':
                pdf_path = symlink.resolve()
                output_prefix = extracts_dir / symlink.stem
                pdf_tasks.append((pdf_path, output_prefix))
    
    console.print(f"[bold cyan]Converting {len(pdf_tasks)} PDF files to images (parallel)...[/bold cyan]")
    
    # Convert PDFs in parallel with progress tracking
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TimeRemainingColumn(),
        console=console
    ) as progress:
        task = progress.add_task("Converting PDFs", total=len(pdf_tasks))
        
        with ProcessPoolExecutor(max_workers=4) as executor:
            futures = {
                executor.submit(_convert_pdf_to_images, pdf_path, output_prefix): (pdf_path, output_prefix)
                for pdf_path, output_prefix in pdf_tasks
            }
            
            for future in _as_completed(futures):
                success, message = future.result()
                if success:
                    console.print(f"  [green]✓[/green] {message}")
                else:
                    console.print(f"  [red]✗[/red] {message}")
                progress.advance(task)
    
    console.print(f"\n[bold green]Done![/bold green] Images saved to: {extracts_dir}")


# TODO:
#   - [ ] `j new log`
#   - [ ] `j new directory`
