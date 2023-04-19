#/bin/python3
import sys

text = ''

for line in sys.stdin:
    text += line
text += '\n'

count = 0
token = ''

for c in text:
    if c == ' ' or c == '\n':
        if token:
            count += 1
            token = ''
    elif c.isascii():
        token += c
    else:
        count += 1
        if token:
            count += 1
            token = ''


print(count, end='')

