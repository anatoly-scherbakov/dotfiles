---
name: close-idle-sessions
description: Find the idle sessions in the fleet you coordinate, have each confirm it is idle and safe to close, and give the user a list to close. An idle session left open overnight has an expired prompt cache, so a later message re-reads its whole context at full price. Use for "/close-idle-sessions", "I'm going offline", "which sessions can I close", "close the idle sessions".
---

# close-idle-sessions

Run it from the coordinating session (the one that spawned or routes the
workers). It only identifies idle sessions. It never stops, pauses or
redirects a session that has work to do, and the user closes the windows.

1. **List the fleet.** Run `ListAgents`. Keep only the sessions this session
   coordinates: ones it spawned, messages or relays for. Leave every other
   session alone.
2. **Pick the idle ones.** A session is idle when it has nothing left to do:
   its PR is merged or handed off, its goal is finished, or it is parked on
   something outside it (a review, someone's answer). A session that is busy or
   still has its own steps to work through is not idle. Leave it running and
   don't message it.
3. **Ask each idle session to tell the user.** Send one `SendMessage` asking it
   to say **in its own window, to the user**, that it is idle and can be closed.
   Replying to the user ends its turn, and that flags its window as urgent in
   the window manager, so the user can find it and close it. If it has anything
   pending (an unpushed change, a trigger it was watching, an open question), it
   says that in the same reply, in one or two lines with full URLs, and also
   sends those lines back to the coordinating session. Say nothing about the
   user being offline, and don't ask it to stop or wrap up work.
4. **Give the user the list.** Show a table of each session asked, plus
   anything it reported as pending. Take over watching any trigger it named,
   from this session's own loop. Sessions that said they aren't idle stay open;
   list them separately. The user closes the windows. Claude cannot close
   another session.

A session with a permission prompt pending can't reply. List it as "blocked on
a prompt" rather than closable.
