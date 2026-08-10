import datetime
import tempfile
import unittest
from pathlib import Path
import jeeves


class OrganizeTests(unittest.TestCase):
    def test_archives_concluded_months_and_preserves_current_month(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / '2026-01-02.notes.md').touch()
            (root / '2026-03-20.from-sd-card').mkdir()
            (root / '2026-08-10.current.md').touch()

            jeeves._organize(root, datetime.date(2026, 8, 11), dry_run=False)

            self.assertTrue((root / '2026-01' / '2026-01-02.notes.md').exists())
            self.assertTrue((root / '2026-03' / '2026-03-20.from-sd-card').is_dir())
            self.assertTrue((root / '2026-08-10.current.md').exists())

    def test_moves_previous_year_month_archives_into_the_year(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / '2025-12').mkdir()

            jeeves._organize(root, datetime.date(2026, 8, 11), dry_run=False)

            self.assertTrue((root / '2025' / '2025-12').is_dir())

    def test_dry_run_does_not_change_the_filesystem(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            entry = root / '2026-01-02.notes.md'
            entry.touch()

            jeeves._organize(root, datetime.date(2026, 8, 11), dry_run=True)

            self.assertTrue(entry.exists())
            self.assertFalse((root / '2026-01').exists())
