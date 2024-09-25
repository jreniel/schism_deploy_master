BRANCH ?= master

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_PARENT := $(dir $(MAKEFILE_PATH))
DESTDIR ?= ${HOME}/.local/share/schism/${BRANCH}

# Default compiler and MPI implementation
CC ?= gcc
FC ?= gfortran
MPICC ?= mpicc
MPIFC ?= mpif90

define get_loaded_modules
$(shell if command -v module >/dev/null 2>&1; then module list 2>&1 | grep -v "No modules loaded" | awk '{print $$2}' | paste -sd " "; else echo ""; fi)
endef


# Detect loaded modules
LOADED_MODULES := $(call get_loaded_modules)

# Function to set compilers based on loaded modules
define set_compiler
$(eval CC = $(shell echo "$(1)" | grep -q "intel" && echo "icx" || echo "$(CC)"))
$(eval FC = $(shell echo "$(1)" | grep -q "intel" && echo "ifx" || echo "$(FC)"))
$(eval MPICC = $(shell echo "$(1)" | grep -q "intel-mpi" && echo "mpiicc" || echo "$(MPICC)"))
$(eval MPIFC = $(shell echo "$(1)" | grep -q "intel-mpi" && echo "mpiifort" || echo "$(MPIFC)"))
endef

# Set compilers based on loaded modules
$(eval $(call set_compiler,$(LOADED_MODULES)))

# break if nc-config not found
ifeq ($(shell which nc-config),)
    $(error "nc-config not found. Please ensure NetCDF C library is properly installed and nc-config is in your PATH")
endif

# break if nf-config not found
ifeq ($(shell which nf-config),)
    $(error "nf-config not found. Please ensure NetCDF Fortran library is properly installed and nf-config is in your PATH")
endif

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
	@echo "Building SCHISM with detected environment"
	@echo "Loaded modules: $(LOADED_MODULES)"
	@echo "CC: $(CC)"
	@echo "FC: $(FC)"
	@echo "MPICC: $(MPICC)"
	@echo "MPIFC: $(MPIFC)"
	@rm -rf build
	@mkdir build
	@cd build && \
	cmake $(CACHE_DIR)/src $(CMAKE_ALL_OPTS) && \
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
	echo "prepend-path PATH {${DESTDIR}/bin}" >> $${modulefile}; \
	echo '' >> $${modulefile}; \
	echo '# Load required modules' >> $${modulefile}; \
	for module in $(LOADED_MODULES); do \
		echo "if { [module-info mode load] && [is-loaded $$module] } {" >> $${modulefile}; \
		echo "    module load $$module" >> $${modulefile}; \
		echo "}" >> $${modulefile}; \
	done; \
	echo '' >> $${modulefile}; \
	echo '# Set environment variables' >> $${modulefile}; \
	echo "setenv SCHISM_ROOT ${DESTDIR}" >> $${modulefile}; \
	echo "setenv SCHISM_BRANCH ${BRANCH}" >> $${modulefile}; \
	echo '' >> $${modulefile};

clean:
	rm -rf ${MAKEFILE_PARENT}build

.PHONY: default update-cache build install modulefiles sciclone clean refresh
