import unittest
import mock
import fix_gcovr_paths


class TestRead(unittest.TestCase):

    @mock.patch('__builtin__.file')
    @mock.patch('__builtin__.open')
    def test_read_when_file_exists(self, mock_open, mock_file):
        text = 'I love mocking files'
        mock_open.return_value = mock_file
        mock_file.read.return_value = text

        fixer = fix_gcovr_paths.PathFixer()
        fixer.read_file('some_file.xml')

        self.assertEquals(text, fixer.content)

    @mock.patch('__builtin__.open')
    def test_read_when_no_file(self, mock_open):
        def fake_open(*args, **kwargs):
            raise IOError('No such file or directory')

        mock_open.side_effect = fake_open

        fixer = fix_gcovr_paths.PathFixer()

        self.assertRaises(IOError, fixer.read_file, 'non_existing_file.xml')


class TestFind(unittest.TestCase):

    @mock.patch('os.walk')
    def test_find_existing_file(self, mock_walk):
        mock_walk.return_value = [('/root', [], ['foo.txt', 'bar.txt'])]

        path = fix_gcovr_paths.PathFixer.find('foo.txt', '/')

        self.assertEquals('/root/foo.txt', path)

    @mock.patch('os.walk')
    def test_find_no_file(self, mock_walk):
        mock_walk.return_value = [('/root', [], ['foo.txt'])]

        path = None

        self.assertRaises(
            fix_gcovr_paths.FileNotFoundException,
            fix_gcovr_paths.PathFixer.find,
            'bar.txt',
            '/root')

    @mock.patch('os.walk')
    def test_find_two_files_with_same_name(self, mock_walk):
        mock_walk.return_value = [
            ('/root', ['subdir'], ['foo.txt']),
            ('/root/subdir', [], ['foo.txt'])
        ]

        path = fix_gcovr_paths.PathFixer.find('foo.txt', '/')

        self.assertEquals('/root/foo.txt', path)


class TestFixFilenames(unittest.TestCase):

    @mock.patch('os.walk')
    @mock.patch('os.path.isfile')
    def test_fix_filenames(self, mock_isfile, mock_walk):
        original_content = """
            filename="/foo.c"
            filename="/bar.c"
            filename="/a/b/c/d/test.c"
        """

        expected_content = """
            filename="/dir1/foo.c"
            filename="/dir2/bar.c"
            filename="/a/b/c/d/test.c"
        """

        def fake_isfile(path):
            return path != '/foo.c' and path != '/bar.c'

        mock_isfile.side_effect = fake_isfile

        mock_walk.return_value = [
            ('/dir1', [], ['foo.c']),
            ('/dir2', [], ['bar.c'])
        ]

        fixer = fix_gcovr_paths.PathFixer()
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

        fixer = fix_gcovr_paths.PathFixer()
        fixer.content = original_content

        self.assertRaises(
            fix_gcovr_paths.FileNotFoundException,
            fixer.fix_paths,
            '/')


class TestWriteFile(unittest.TestCase):

    def setUp(self):
        self.file_content = None

    @mock.patch('__builtin__.file')
    @mock.patch('__builtin__.open')
    def test_write_file(self, mock_open, mock_file):
        mock_open.return_value = mock_file

        def fake_write(string):
            self.file_content = string

        mock_file.write.side_effect = fake_write

        fixer = fix_gcovr_paths.PathFixer()
        fixer.content = "My file content"
        fixer.write_file('somefile.xml')

        self.assertEquals("My file content", self.file_content)

    @mock.patch('__builtin__.open')
    def test_write_file_with_error(self, mock_open):
        def fake_open(*args, **kwargs):
            raise IOError('No such file or directory')

        mock_open.side_effect = fake_open

        fixer = fix_gcovr_paths.PathFixer()
        fixer.content = 'Empty'

        self.assertRaises(IOError, fixer.write_file, 'some_file.xml')
        self.assertEquals(None, self.file_content)
