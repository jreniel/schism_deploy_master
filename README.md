# SCHISM Deployment and Module Creation Makefile

This Makefile provides a convenient way to deploy the current master branch of the SCHISM repository and create a loadable module for it. It's designed to work both with and without a module system, making SCHISM easily accessible in various environments.

## Features

- Compiles and installs SCHISM from the current master branch
- Creates a loadable module file for SCHISM (compatible with Lmod)
- Works with or without system modules loaded
- Doesn't require elevated privileges
- Allows customization of CMake options for flexible builds

## Prerequisites

- Access to the SCHISM repository
- GCC or Intel compilers
- MPI libraries
- NetCDF libraries
- (Optional) Lmod or another module system

## Usage

### 1. Compilation Environment

You have two options for setting up your compilation environment:

a) **Using system modules:**
If you have modules available, load them before running make. For example:

```bash
module load intel/compiler-2024.0 intel/mpi-2021.11 netcdf-c/intel-2024.0/4.9.2_intelmpi netcdf-fortran/intel-2024.0/4.6.1_intelmpi
```

b) **Using system libraries:**
If you're not using modules, ensure that your system libraries (compilers, MPI, NetCDF) are in your PATH and LD_LIBRARY_PATH.

### 2. Run Make Commands

Compile and install SCHISM:

```bash
make && make install
```

### 3. Installation Directory

By default, SCHISM will be installed in:

```
${HOME}/.local/share/schism/${BRANCH}
```

Where ${BRANCH} is typically "master" for the current version.

### 4. Module File Creation

The Makefile will create a module file at:

```
${HOME}/.local/Modules/modulefiles/schism/${BRANCH}
```

This file is created regardless of whether you have modules installed on your system.

### 5. Using the Created Module

If you have Lmod or another compatible module system:

a) Add the module directory to your module path:

```bash
module use ${HOME}/.local/Modules/modulefiles
```

Or append it permanently:

```bash
module --append ${HOME}/.local/Modules/modulefiles
```

b) Load the SCHISM module:

```bash
module load schism/${BRANCH}
```

If you don't have a module system, you can source the module file directly or add the SCHISM installation to your PATH manually.

## Customization

### Installation Directory

You can customize the installation directory by setting the DESTDIR variable:

```bash
make DESTDIR=/path/to/custom/directory install
```

### CMake Options

You can pass additional options to CMake using the CMAKE_EXTRA_OPTS variable. This allows you to enable or disable specific features of SCHISM. For example, to enable OLDIO:

```bash
make CMAKE_EXTRA_OPTS="-DOLDIO=ON" install
```

You can compound multiple options in a single command:

```bash
make CMAKE_EXTRA_OPTS="-DOLDIO=ON -DUSE_HA=ON" install
```

**Important Note on Option Compounding:**

1. **Build Directory**: The compilations will compound upon each other in the build directory. Each run of `make` with different CMAKE_EXTRA_OPTS will modify the existing build, incorporating the new options on top of the previous ones.

2. **Clearing Options**: To start fresh with a new set of options, you need to run `make clean` before your new `make` command. This clears the build directory and removes all previously set options.

3. **Installation Directory**: The options also compound in the installation directory, but in a different way. Each unique combination of options results in a separate binary:

   - If you run `make CMAKE_EXTRA_OPTS="-DOPT1=ON" install`, you'll get `binary_OPT1` in the install directory.
   - If you then run `make CMAKE_EXTRA_OPTS="-DOPT2=ON" install` without cleaning, you'll get `binary_OPT1_OPT2` in the install directory, and `binary_OPT1` will still be there.
   - If you want to compile a `binary_OPT2`, version, you need to run `make clean` first, then `make CMAKE_EXTRA_OPTS="-DOPT2=ON" install`. The binaries `binary_OPT1_OPT2` and `binary_OPT1` will still remain in the installation directory, having added `binary_OPT2` alongside.

4. **Multiple Configurations**: This behavior allows you to build and keep multiple binary versions with different option combinations in the same installation directory.

Example workflow:

```bash
# Build with OPT1
make CMAKE_EXTRA_OPTS="-DOPT1=ON" install
# Results in binary_OPT1 in install directory

# Add OPT2 (compounds with OPT1)
make CMAKE_EXTRA_OPTS="-DOPT2=ON" install
# Results in binary_OPT1_OPT2 in install directory (binary_OPT1 still exists)

# Clean and build with only OPT2
make clean
make CMAKE_EXTRA_OPTS="-DOPT2=ON" install
# Results in binary_OPT2 in install directory (binary_OPT1 and binary_OPT1_OPT2 still exist)
```

This approach gives you flexibility in managing multiple SCHISM configurations while keeping track of the options used for each build.

## Troubleshooting

### Common Issues

1. **Missing `nc-config` or `nf-config`**

   If you encounter an error stating that `nc-config` or `nf-config` are not in PATH, ensure that your NetCDF libraries are correctly installed and their bin directories are in your PATH.

2. **Compilation Errors**

   Double-check that all necessary libraries (MPI, NetCDF) are available and their paths are correctly set in your environment.

3. **CMake Errors**

   If you encounter errors related to CMake options, ensure that the options you're passing via CMAKE_EXTRA_OPTS are valid for your version of SCHISM. Refer to the SCHISM documentation for a list of available options.

## Support

For issues related to SCHISM itself, please refer to the [official SCHISM documentation](https://schism.wiki/) or repository. For problems specific to this Makefile, consider opening an issue in the repository where this Makefile is hosted.

## Disclaimer

This is a convenience script designed to simplify SCHISM deployment. While it aims to be flexible, it may not cover all possible scenarios. Always refer to the official SCHISM documentation for the most up-to-date and comprehensive installation instructions.
