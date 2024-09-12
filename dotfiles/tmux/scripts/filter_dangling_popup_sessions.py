#!/usr/bin/env python3

"""
filter dangling popup tmuc sessions, takes input from `tmux ls -F "#S"`
"""

popup_sessions = []
regular_sessions = []

while True:
    try:
        name = input()
        if name.endswith("__popup"):
            popup_sessions.append(name)
        else:
            regular_sessions.append(name)
    except EOFError:
        break


dangling_popup_sessions = [
    name for name in popup_sessions if name[:-7] not in regular_sessions
]

print("\n".join(dangling_popup_sessions))
