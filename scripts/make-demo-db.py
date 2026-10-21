#!/usr/bin/env -S python3 -I
"""Writes a synthetic events.sqlite (fake working days, no real data) for demos, screenshots and tests.
Usage: make-demo-db.py PATH   then   SESSION_DB=PATH session-dashboard 8766
       or  HOME=<dir containing .local/share/session-tracker/events.sqlite> session-report"""
import datetime as dt, random, sqlite3, sys

path = sys.argv[1]
rnd = random.Random(42)  # fixed seed: same demo every run
T = lambda d, h: int(dt.datetime.combine(d, dt.time()).timestamp() + h * 3600)
db = sqlite3.connect(path)
db.executescript('''DROP TABLE IF EXISTS events; DROP TABLE IF EXISTS derived;
CREATE TABLE events(ts INTEGER NOT NULL, event TEXT NOT NULL);
CREATE TABLE derived(ts_from INTEGER NOT NULL, ts_to INTEGER NOT NULL, source TEXT NOT NULL);''')

today = dt.date.today()
first_tracked = today - dt.timedelta(days=80)
vacation = (today - dt.timedelta(days=35), today - dt.timedelta(days=24))


def sessions(d):
    """Presence blocks as (start_h, end_h) of one fake day."""
    if vacation[0] <= d <= vacation[1]:
        return []
    if d.weekday() >= 5:
        return [(10 + rnd.random() * 3, 11.5 + rnd.random() * 2)] if rnd.random() < .15 else []
    if rnd.random() < .06:  # sick day / day off
        return []
    a, b = 8.3 + rnd.random() * 1.5, 17 + rnd.random() * 2.5
    lunch = (12 + rnd.random() * .5, 13 + rnd.random() * .7)
    out = [(a, lunch[0]), (lunch[1], b)]
    if rnd.random() < .4:  # a short pause inside the afternoon block
        c = lunch[1] + 1 + rnd.random() * 2
        out[1:] = [(lunch[1], c), (c + .2 + rnd.random() * .3, b)]
    return out


d = first_tracked
while d < today:
    for a, b in sessions(d):
        db.execute('INSERT INTO events VALUES (?, ?)', (T(d, a), 'unlock'))
        for t in range(T(d, a) + 300, T(d, b), 300):
            db.execute('INSERT INTO events VALUES (?, ?)', (t, 'alive'))  # heartbeat every 5 min, like the real tracker
        db.execute('INSERT INTO events VALUES (?, ?)', (T(d, b), 'lock'))
    d += dt.timedelta(days=1)

# Derived evidence for the months before tracking: sparse points from three fake sources.
d = first_tracked - dt.timedelta(days=200)
while d < first_tracked:
    if d.weekday() < 5 and rnd.random() > .08:
        for src, step in (('browser_chrome', 12), ('shell_history', 25), ('knowledgec_app', 8)):
            h = 9 + rnd.random()
            while h < 17.5 + rnd.random():
                db.execute('INSERT INTO derived VALUES (?, ?, ?)', (T(d, h), T(d, h), src))
                h += step / 60 * (.5 + rnd.random())
    d += dt.timedelta(days=1)
db.commit()
print(path, db.execute('SELECT COUNT(*) FROM events').fetchone()[0], 'events,', db.execute('SELECT COUNT(*) FROM derived').fetchone()[0], 'derived rows')
