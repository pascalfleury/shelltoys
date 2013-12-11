import os
from os import path
from time import time, localtime, strftime
import random
import shutil
import mkdirs
import random
import filecmp

class RevisionedStorage(object):

  def __init__(self, dir):
    self.rootdir = dir
    mkdirs.mkdirs(self.rootdir)

  class TempRevFile(file):
    """Class for a temporary revisioned file that triggers rev ops at close."""
    def __init__(self, outfilename, revstore, args):
      self.revstore = revstore
      self.args = args
      self.filename = outfilename
      file.__init__(self, self.filename, "w")

    def close(self):
      file.close(self)
      self.revstore._close(self.filename, self.args)

  def open(self, token):
    """Opens a temp file for a token, returns the filehandle."""
    if token[0:1] == '/':
      token = token[1:]
    linkfile=path.join(self.rootdir, token)
    revsdir = "%s-revs" % linkfile
    mkdirs.mkdirs(revsdir)
    timestamp = strftime("%Y%m%d-%H%M%S", localtime(time()))
    counter = 1
    while path.exists(path.join(revsdir, timestamp)):
      counter += 1
      timestamp = "%s-%d" % (timestamp, counter)
    extension = "-edit%d" % (int(random.random() * 10000))
    outfilename = path.join(revsdir, "%s-%s" % (timestamp, extension))
    args = (linkfile, timestamp, extension, revsdir)
    return RevisionedStorage.TempRevFile(outfilename, self, args)

  def _close(self, outfile, args):
    """Called when a TempRevFile is closed, to update the revisioning."""
    (linkfile, timestamp, extension, revsdir) = args
    finalfile = path.join(revsdir, timestamp)
    if not path.exists(linkfile):
      shutil.move(outfile, finalfile)
      os.symlink(finalfile, linkfile)
    else:
      if not filecmp.cmp(linkfile, outfile):
        shutil.move(outfile, finalfile)
        os.remove(linkfile)
        os.symlink(finalfile, linkfile)
      else:
        os.remove(outfile)

  def commit(self, filename, basedir="/"):
    skip = len(path.commonprefix([filename, basedir]))
    sink = self.open(filename[skip:])
    source = open(filename, "r")
    shutil.copyfileobj(source, sink)
    source.close()
    sink.close()
