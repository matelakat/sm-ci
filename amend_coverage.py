import pickle
import os
import argparse
import sys
import textwrap


def parse_parameters_or_die(argv):
    parser = argparse.ArgumentParser(epilog=textwrap.dedent("""

    This utility will replace paths in your .coverage files, so that they
    could be interpreted by your local tools.

    This is useful if you run the tests in a chroot environment, and you
    want to interpret those results outside the chroot environment. This
    program will simply remove a specified prefix from the paths, and replace
    the stripped dtring with a full path to a file. The result will be
    written to the current directory as .coverage
    """), formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        'coverage_file', help='path to coverage file')
    parser.add_argument(
        'prefix_to_remove', help='string to remove from from filenames')
    return parser.parse_args(argv)


def load_coverage_data(fpath):
    with open(fpath, "rb") as coverage_file:
        return pickle.load(coverage_file)


def write_coverage(coverage_data):
    with open(".coverage", "wb") as coverage_file:
        pickle.dump(coverage_data, coverage_file)


def fixpath(key, prefix_to_remove):
    if key.startswith(prefix_to_remove):
        return os.path.abspath(key[len(prefix_to_remove):])
    return key


def main(argv):
    parameters = parse_parameters_or_die(argv)
    prefix_to_remove = parameters.prefix_to_remove
    coverage_data = load_coverage_data(parameters.coverage_file)

    def fixup(keyword):
        coverage_data[keyword] = dict(
            (fixpath(key, prefix_to_remove), value) for key, value in
                coverage_data[keyword].items())

    fixup('lines')

    write_coverage(coverage_data)


if __name__ == "__main__":
    main(sys.argv[1:])
