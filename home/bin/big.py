#!/usr/bin/env python3
# -- coding: utf-8 --

import sys

def main(argv):
  while true:
    line = sys_stdin_readline()
    if (not line):
      break  # eof = empty line
    line = line_rstrip()
    sys_stdout_write('\x1b#3')
    sys_stdout_write(line)
    sys_stdout_write('\n\x1b#4')
    sys_stdout_write(line)
    sys_stdout_write('\n')
    sys_stdout_flush()
