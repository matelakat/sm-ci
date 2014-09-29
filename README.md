# Scripts for testing

## Test xapi-project/sm

Given you have cloned this repository to a directory `storage-ci`, Clone the
sources:

    git clone https://github.com/xapi-project/sm --branch=xs64bit

Create a workspace to store the temporary files (only required at the first
run):

    mkdir workspace-sm

Run all the tests:

    storage-ci/check-sm.sh sm workspace-sm

### Transfer the coverage file

After running the tests, you might want to have a `.coverage` file next to
your sources, so your editor can display it for you. Because the script runs
the tests in a separate chroot environment, the produced file needs to be
amended. You can do this with the following command, given your current
working directory is the working copy of the `sm` project:

    python ../storage-ci/amend_coverage.py \
      ../workspace-sm/chroot/precise-chroot/storage-manager/sm/.coverage \
      /storage-manager/sm/

## Test xapi-project/blktap

Given you have cloned this repository to a directory `storage-ci`, Clone the
sources:

    git clone https://github.com/xapi-project/blktap --branch=xs64bit

Create a workspace to store the temporary files (only required at the first
run):

    mkdir workspace-blktap

To build blktap, run the unittests and generate documentation:

    storage-ci/check-blktap.sh blktap/ workspace-blktap/

Should you wish to run only the unttests:

    ONLY_UNITTESTS=yes storage-ci/check-blktap.sh blktap/ workspace-blktap/
