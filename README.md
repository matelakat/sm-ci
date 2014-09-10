# Scripts for testing

To be able to test code without being scared about the side effects,
a fakechroot environment is created. This environment is called `chroot`.

To transfer the source code to the `chroot` the source code is packaged as
a `.tgz` to a so-called `source_pack` and extracted inside the `chroot`.

 - A `chroot` could be created.
 - A `chroot` could be dumped to a `.tgz` file.
 - A `chroot` could be restored from a `.tgz` file.
 - A tarball file, `source_pack` could be created from the sources.
 - A `source_pack` could be used to install the prerequisites to an `chroot`.
 - A `source_pack` could be used to create the python test environment within
   `chroot`.
 - Unit tests could be ran in an `chroot` that has all the prerequisites
   installed and the python test environment created.

## Public interface

There is no public interface for the library. The public interface consists
of the scripts:

    check-sm.sh
    check-blktap.sh

## Example

To run the tests on storage manager, given that this directory is checked
out to `../sm-ci` and you have a directory `../workspace-sm-xs64bit`, you run
the tests:

    ../sm-ci/check-sm.sh ./ ../workspace-sm-xs64bit/

And transfer the coverage file:


```

python ../sm-ci/amend_coverage.py \
  ../workspace-sm-xs64bit/chroot/precise-chroot/storage-manager/sm/.coverage \
  /storage-manager/sm/

```
