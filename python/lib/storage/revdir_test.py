#!/usr/bin/python

import os
from os import path
import tempfile
import shutil
import mkdirs
from revdir import RevisionedStorage

# Testing the revdir.py class

TMPDIR=tempfile.mkdtemp()
print "Storm happening in %s" % TMPDIR
REVDIR=path.join(TMPDIR, "revd")
mkdirs.mkdirs(REVDIR)
SRCDIR=path.join(TMPDIR, "src")
mkdirs.mkdirs(SRCDIR)
print "REVDIR=%s  SRCDIR=%s" % (REVDIR, SRCDIR)

def mkfile(filename, content):
  if filename[0:1] == '/':
    filename = filename[1:]
  realfile = path.join(SRCDIR, filename)
  realdir = path.dirname(realfile)
  print "Creating %s in %s [SRCDIR=%s]" % (realfile, realdir, SRCDIR)
  mkdirs.mkdirs(realdir)
  of = open(realfile, "w")
  of.write(content)
  of.close()


mkfile("/sample1/file1.txt", "This is the content of the file.")
mkfile("/sample1/file2.txt", "This is the content of the file.")
mkfile("/ex1/afile.txt", "This is the content of the file.")
mkfile("/ex2/afile.txt", "This is the content of the file.")

RD = RevisionedStorage(REVDIR)
RD.commit(path.join(SRCDIR, "sample1/file1.txt"), SRCDIR)
RD.commit(path.join(SRCDIR, "sample1/file2.txt"), SRCDIR)
RD.commit(path.join(SRCDIR, "ex1/afile.txt"), SRCDIR)
RD.commit(path.join(SRCDIR, "ex2/afile.txt"), SRCDIR)
mkfile("/ex1/afile.txt", "Ooops, some new content.")
RD.commit(path.join(SRCDIR, "ex1/afile.txt"), SRCDIR)

#rmtree(TMPDIR)