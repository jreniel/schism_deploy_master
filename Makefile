BRANCH ?= master

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_PARENT := $(dir $(MAKEFILE_PATH))
DESTDIR ?= ${HOME}/.local/share/schism/${BRANCH}

# Detect the environment
UNAME := $(shell uname)
HOSTNAME := $(shell hostname)

# Default compiler and MPI implementation
CC ?= gcc
FC ?= gfortran
MPICC ?= mpicc
MPIFC ?= mpif90

# NetCDF configuration
NETCDF_C_PREFIX ?= $(shell nc-config --prefix)
NETCDF_F_PREFIX ?= $(shell nf-config --prefix)

# CMake options
CMAKE_OPTS ?= -DNetCDF_Fortran_LIBRARY=$(NETCDF_F_PREFIX)/lib/libnetcdff.so \
              -DNetCDF_C_LIBRARY=$(NETCDF_C_PREFIX)/lib/libnetcdf.so \
              -DNetCDF_INCLUDE_DIR=$(NETCDF_C_PREFIX)/include/ \
			  -DBLD_STANDALONE=ON

# Allow additional CMake options to be added
CMAKE_EXTRA_OPTS ?=

# Combine default and extra CMake options
CMAKE_ALL_OPTS = $(CMAKE_OPTS) $(CMAKE_EXTRA_OPTS)

# Number of parallel jobs for make
NPROC ?= $(shell nproc)

# Cache directory for SCHISM repository
CACHE_DIR ?= ${HOME}/.cache/schism-repo

# Function to refresh modules
define refresh_modules
	@if command -v module >/dev/null 2>&1; then \
		echo "Refreshing modules..."; \
		if module refresh >/dev/null 2>&1; then \
			echo "Modules refreshed using 'module refresh'"; \
		elif module reload >/dev/null 2>&1; then \
			echo "Modules reloaded using 'module reload'"; \
		else \
			echo "Unable to refresh modules automatically. You may need to manually reload your modules."; \
		fi; \
	else \
		echo "Module command not found. Skipping module refresh."; \
	fi
endef

default: build

update-cache:
	@echo "Updating SCHISM repository cache..."
	@mkdir -p $(CACHE_DIR)
	@if [ -d $(CACHE_DIR)/.git ]; then \
		git -C $(CACHE_DIR) fetch --all --prune; \
		git -C $(CACHE_DIR) reset --hard origin/$(BRANCH); \
	else \
		git clone https://github.com/schism-dev/schism $(CACHE_DIR); \
	fi
	@git -C $(CACHE_DIR) checkout $(BRANCH)
	@echo "SCHISM repository cache updated."

build: update-cache
	@echo "Building SCHISM..."
	@mkdir -p build
	@rm -rf build/*
	@cp -r $(CACHE_DIR)/* build/
	@cd build && \
	cmake src $(CMAKE_ALL_OPTS) && \
	make -j $(NPROC) --no-print-directory
	@echo "SCHISM build completed."

install:
	@set -e; \
	mkdir -p ${DESTDIR}; \
	cp -r build/bin ${DESTDIR}/; \
	$(MAKE) modulefiles --no-print-directory

modulefiles:
	@set -e; \
	prefix=$${HOME}/.local/Modules/modulefiles/schism; \
	mkdir -p $${prefix}; \
	modulefile=$${prefix}/${BRANCH}; \
	echo '#%Module1.0' > $${modulefile}; \
	echo '#' >> $${modulefile}; \
	echo '# SCHISM ${BRANCH} tag' >> $${modulefile}; \
	echo '#' >> $${modulefile}; \
	echo '' >> $${modulefile}; \
	echo 'proc ModulesHelp { } {' >> $${modulefile}; \
	echo "puts stderr \"SCHISM loading from ${BRANCH} branch from a local compile @ ${DESTDIR}.\"" >> $${modulefile}; \
	echo '}' >> $${modulefile}; \
	echo "prepend-path PATH {${DESTDIR}/bin}" >> $${modulefile}

# Environment-specific configurations
ifeq ($(HOSTNAME),sciclone)
sciclone: CC = icc
sciclone: FC = ifort
sciclone: MPICC = mpiicc
sciclone: MPIFC = mpiifort
sciclone:
	@echo "Building for Sciclone environment"
	@module purge
	@module load intel/2018 intel/2018-mpi netcdf/4.4.1.1/intel-2018 netcdf-fortran/4.4.4/intel-2018 cmake
	$(call refresh_modules)
	$(MAKE) build install modulefiles --no-print-directory
else
# Add other environment-specific configurations here
# For example:
# ifeq ($(HOSTNAME),other-cluster)
# other-cluster: CC = ...
# other-cluster: FC = ...
# other-cluster:
#     @echo "Building for other-cluster environment"
#     @module load ...
#     $(call refresh_modules)
#     $(MAKE) build install modulefiles --no-print-directory
# endif
endif

refresh:
	$(call refresh_modules)

clean:
	rm -rf ${MAKEFILE_PARENT}build

.PHONY: default update-cache build install modulefiles sciclone clean refresh
