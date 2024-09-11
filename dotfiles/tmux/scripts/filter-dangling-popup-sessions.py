#!/usr/bin/env python3

session_names = []
while True:
    try:
        session_names.append(input())
    except EOFError:
        break

popup_sessions = [name for name in session_names if name.endswith("__popup")]
regular_sessions = [name for name in session_names if not name.endswith("__popup")]

dangling_popup_sessions = [
    name for name in popup_sessions if name[:-7] not in regular_sessions
]

print("\n".join(dangling_popup_sessions))
