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

    def test_rsync_omits_unsupported_destination_metadata(self):
        arguments = jeeves._rsync_arguments()

        self.assertIn('--no-links', arguments)
        self.assertIn('--no-owner', arguments)
        self.assertIn('--no-group', arguments)
        self.assertIn('--no-perms', arguments)
        self.assertIn('--delete-delay', arguments)

    def test_symlink_excludes_are_anchored_to_the_sync_root(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary_root = Path(temporary_directory)
            root = temporary_root / 'source'
            destination = temporary_root / 'destination'
            root.mkdir()
            (root / 'nested').mkdir()
            destination.mkdir()
            (root / 'nested' / 'link').symlink_to('../target')
            (destination / 'remote-only-link').symlink_to('target')

            self.assertEqual(
                jeeves._symlink_excludes(root, destination),
                ['/nested/link', '/remote-only-link'],
            )
