#!/usr/bin/env python

"""
Correct invalid filenames in a gcover XML report.

Known limitation: if several files have the same name, there is no guarantee
that this script will determine the correct path for each of them.
"""

import sys
import re
import os.path
import unittest
import mock


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

        raise FileNotFoundException("Could not find %s in %s" % (file_basename, base_dir))

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


class TestRead(unittest.TestCase):

    @mock.patch('__builtin__.file')
    @mock.patch('__builtin__.open')
    def test_read_when_file_exists(self, mock_open, mock_file):
        text = 'I love mocking files'
        mock_open.return_value = mock_file
        mock_file.read.return_value = text

        fixer = PathFixer()
        fixer.read_file('some_file.xml')

        self.assertEquals(text, fixer.content)

    @mock.patch('__builtin__.open')
    def test_read_when_no_file(self, mock_open):
        def fake_open(*args, **kwargs):
            raise IOError('No such file or directory')

        mock_open.side_effect = fake_open

        fixer = PathFixer()

        try:
            fixer.read_file('non_existing_file.xml')
        except IOError:
            pass

        self.assertEquals(None, fixer.content)


class TestFind(unittest.TestCase):

    @mock.patch('os.walk')
    def test_find_existing_file(self, mock_walk):
        mock_walk.return_value = [('/root', [], ['foo.txt', 'bar.txt'])]

        path = PathFixer.find('foo.txt', '/')

        self.assertEquals('/root/foo.txt', path)

    @mock.patch('os.walk')
    def test_find_no_file(self, mock_walk):
        mock_walk.return_value = [('/root', [], ['foo.txt'])]

        path = None

        try:
            path = PathFixer.find('bar.txt', '/root')
        except FileNotFoundException:
            pass

        self.assertEquals(None, path)

    @mock.patch('os.walk')
    def test_find_two_files_with_same_name(self, mock_walk):
        mock_walk.return_value = [
            ('/root', ['subdir'], ['foo.txt']),
            ('/root/subdir', [], ['foo.txt'])
        ]

        path = PathFixer.find('foo.txt', '/')

        self.assertEquals('/root/foo.txt', path)


class TestFixFilenames(unittest.TestCase):

    @mock.patch('os.walk')
    @mock.patch('os.path.isfile')
    def test_fix_filenames(self, mock_isfile, mock_walk):
        original_content = (
            'filename="/foo.c"\n'
            'filename="/bar.c"\n'
            'filename="/a/b/c/d/test.c"'
        )

        expected_content = (
            'filename="/dir1/foo.c"\n'
            'filename="/dir2/bar.c"\n'
            'filename="/a/b/c/d/test.c"'
        )

        def fake_isfile(path):
            return path != '/foo.c' and path != '/bar.c'

        mock_isfile.side_effect = fake_isfile

        mock_walk.return_value = [
            ('/dir1', [], ['foo.c']),
            ('/dir2', [], ['bar.c'])
        ]

        fixer = PathFixer()
        fixer.content = original_content
        fixer.fix_paths('/')

        self.assertEquals(expected_content, fixer.content)

    @mock.patch('os.walk')
    @mock.patch('os.path.isfile')
    def test_fix_filenames_with_non_existing_file(
            self,
            mock_isfile,
            mock_walk):
        original_content = 'filename="/foo.c"'

        def fake_isfile(path):
            return False

        mock_isfile.side_effect = fake_isfile

        mock_walk.return_value = [('/', [], [])]

        fixer = PathFixer()
        fixer.content = original_content

        try:
            fixer.fix_paths('/')
        except FileNotFoundException:
            pass

        self.assertEquals(original_content, fixer.content)


class TestWriteFile(unittest.TestCase):

    def setUp(self):
        self.tmp = None

    @mock.patch('__builtin__.file')
    @mock.patch('__builtin__.open')
    def test_write_file(self, mock_open, mock_file):
        mock_open.return_value = mock_file

        def fake_write(string):
            self.tmp = string

        mock_file.write.side_effect = fake_write

        fixer = PathFixer()
        fixer.content = "My file content"
        fixer.write_file('somefile.xml')

        self.assertEquals("My file content", self.tmp)

    @mock.patch('__builtin__.open')
    def test_write_file_with_error(self, mock_open):
        def fake_open(*args, **kwargs):
            raise IOError('No such file or directory')

        mock_open.side_effect = fake_open

        fixer = PathFixer()
        fixer.content = 'Empty'

        try:
            fixer.write_file('some_file.xml')
        except IOError:
            pass

        self.assertEquals(None, self.tmp)


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
