"""Cache of the derived blocks in session-dashboard: hit, per-gap key, invalidation by backfill and by a new first event."""
import importlib.util, os, shutil, sqlite3, subprocess, sys, tempfile, time, unittest
from importlib.machinery import SourceFileLoader

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class DerivedCache(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home = tempfile.mkdtemp()
        os.makedirs(cls.home + '/.local/bin')
        for f in ('session-report', 'session-dashboard'):
            shutil.copy(f'{ROOT}/bin/{f}', f'{cls.home}/.local/bin/{f}')
        cls.db = cls.home + '/events.sqlite'
        subprocess.run([sys.executable, '-I', f'{ROOT}/scripts/make-demo-db.py', cls.db], check=True, capture_output=True)
        os.environ.update(HOME=cls.home, SESSION_DB=cls.db)  # the module reads both at import time
        spec = importlib.util.spec_from_loader('dash', SourceFileLoader('dash', f'{cls.home}/.local/bin/session-dashboard'))
        argv, sys.argv = sys.argv, ['session-dashboard']  # the module reads the port from argv at import time
        try:
            cls.dash = importlib.util.module_from_spec(spec); spec.loader.exec_module(cls.dash)
        finally:
            sys.argv = argv

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.home, ignore_errors=True)

    def setUp(self):
        self.dash._cache.clear()
        self.calls = 0
        real = self.dash.report.derived_blocks

        def counting(*a):
            self.calls += 1
            return real(*a)
        self.dash.report.derived_blocks = counting
        self.addCleanup(setattr, self.dash.report, 'derived_blocks', real)

    def test_hit_per_gap_and_same_result(self):
        first = self.dash.data(5.0, True, 1.0)
        self.assertEqual(self.calls, 1)
        self.assertEqual(self.dash.data(5.0, True, 1.0)['blocks'], first['blocks'])
        self.assertEqual(self.calls, 1, 'second call must be served from the cache')
        self.dash.data(10.0, True, 1.0)
        self.assertEqual(self.calls, 2, 'a different gap is a different cache entry')
        self.dash.data(5.0, False, 1.0)
        self.assertEqual(self.calls, 2, 'derived=0 must not touch derived blocks at all')

    def test_new_tracked_event_shows_up_without_recomputing_derived(self):
        before = self.dash.data(5.0, True, 1.0)
        db = sqlite3.connect(self.db)
        t = int(time.time())
        db.executemany('INSERT INTO events VALUES (?, ?)', [(t - 600, 'unlock'), (t - 300, 'alive'), (t, 'alive')]); db.commit()
        after = self.dash.data(5.0, True, 1.0)
        self.assertEqual(self.calls, 1, 'tracked events do not invalidate derived blocks')
        self.assertGreater(len(after['blocks']), len(before['blocks']))

    def test_backfill_invalidates(self):
        self.dash.data(5.0, True, 1.0)
        db = sqlite3.connect(self.db)
        t = db.execute('SELECT MIN(ts_from) FROM derived').fetchone()[0]
        db.execute('INSERT INTO derived VALUES (?, ?, ?)', (t - 86400 * 3, t - 86400 * 3, 'shell_history')); db.commit()
        self.dash.data(5.0, True, 1.0)
        self.assertEqual(self.calls, 2, 'a changed derived table must recompute')

    def test_new_first_event_invalidates(self):
        self.dash.data(5.0, True, 1.0)
        db = sqlite3.connect(self.db)
        t = db.execute('SELECT MIN(ts) FROM events').fetchone()[0]
        db.execute('INSERT INTO events VALUES (?, ?)', (t - 86400, 'start')); db.commit()
        self.dash.data(5.0, True, 1.0)
        self.assertEqual(self.calls, 2, 'the cutoff moved, derived blocks must be recomputed')


if __name__ == '__main__':
    unittest.main()
