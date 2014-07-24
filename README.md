# Scripts for testing Storage Manager (SM)

To be able to test SM code without being scared about the side effects,
a fakechroot environment is created. This environment is called `smroot`.

To transfer the SM source code to the `smroot` the source code is packaged as
a `.tgz` to a so-called `sm_pack` and extracted inside the `smroot`.

 - An `smroot` could be created.
 - An `smroot` could be dumped to a `.tgz` file.
 - An `smroot` could be restored from a `.tgz` file.
 - A tarball file, `sm_pack` could be created from a Storage Manager Repository.
 - An `sm_pack` could be used to install the prerequisites to an `smroot`.
 - An `sm_pack` could be used to create the python test environment within
   `smroot`.
 - Unit tests could be ran in an `smroot` that has all the prerequisites
   installed and the python test environment created.

## Library functions `ci_lib.sh`

Exercise the library with:

    test_ci_lib.sh

