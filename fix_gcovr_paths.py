#!/usr/bin/env python

"""
Correct invalid filenames in a gcover XML report.

Known limitation: if several files have the same name, there is no guarantee
that this script will determine the correct path for each of them.
"""

import sys
import re
import os.path


class PathFixer(object):

    def __init__(self):
        self.content = None

    def read_file(self, filename):
        """Read the content of a file and stores it to memory"""

        f = open(filename, 'r')

        try:
            self.content = f.read()
        finally:
            f.close()

    @classmethod
    def find(cls, file_basename, base_dir):
        """Locate a file contained in a given directory"""

        for root, dirs, files in os.walk(base_dir):
            if file_basename in files:
                return os.path.join(root, file_basename)

        raise FileNotFoundException(
            "Could not find %s in %s" % (file_basename, base_dir))

    def fix_paths(self, source_dir):
        """Fix paths stored in memory, looking for files located in
        source_dir"""

        filenames = re.findall('filename="([^"]+)"', self.content)

        for filename in filenames:
            if not os.path.isfile(filename):
                corrected_filename = PathFixer.find(
                    os.path.basename(filename),
                    source_dir)
                self.content = self.content.replace(
                    filename,
                    corrected_filename)

    def write_file(self, filename):
        """Write content stored in memory to a file"""

        f = open(filename, 'w')

        try:
            f.write(self.content)
        finally:
            f.close()


class FileNotFoundException(Exception):
    pass


if __name__ == "__main__":
    def usage():
        print "Usage: %s source_dir input_filename.xml output_filename.xml" \
            % sys.argv[0]

    def are_arguments_ok():
        return os.path.isdir(sys.argv[1]) and \
            os.path.isfile(sys.argv[2]) and \
            not os.path.isdir(sys.argv[3])

    if len(sys.argv) != 4:
        print "Wrong number of arguments."
        usage()
        sys.exit(-1)
    elif not are_arguments_ok():
        print "Something is wrong with the arguments."
        usage()
        sys.exit(-2)

    source_dir = os.path.abspath(sys.argv[1])
    input_filename = sys.argv[2]
    output_filename = sys.argv[3]

    fixer = PathFixer()
    fixer.read_file(input_filename)
    fixer.fix_paths(source_dir)
    fixer.write_file(output_filename)
