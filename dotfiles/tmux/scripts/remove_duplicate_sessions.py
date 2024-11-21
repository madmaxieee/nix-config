#!/usr/bin/env python3

"""
filter duplicate session names
"""

sessions = []
sessions_set = set()
while True:
    try:
        name = input()
        if name in sessions_set:
            sessions.remove(name)
        sessions.append(name)
        sessions_set.add(name)
    except EOFError:
        break

print("\n".join(sessions))
