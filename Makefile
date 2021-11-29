OLDIO=off
BRANCH=master

MAKEFILE_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_PARENT:=$(dir $(MAKEFILE_PATH))
DESTDIR:=${HOME}/.local/share/schism/${BRANCH}

default:
	@set -e;\
	mkdir build;\
	rm -rf schism;\
	git clone https://github.com/schism-dev/schism;\
	if [ "${BRANCH}" != "master" ]; then\
		pushd schism;\
		git checkout ${BRANCH};\
		popd;\
	fi;\
	NETCDF_C_PREFIX=$$(nc-config --prefix);\
	NETCDF_F_PREFIX=$$(nf-config --prefix);\
	opts+=("-DNetCDF_Fortran_LIBRARY=$${NETCDF_F_PREFIX}/lib/libnetcdff.so");\
	opts+=("-DNetCDF_C_LIBRARY=$${NETCDF_C_PREFIX}/lib/libnetcdf.so");\
	opts+=("-DNetCDF_INCLUDE_DIR=$${NETCDF_C_PREFIX}/include/");\
	opts+=("-DOLDIO=${OLDIO}");\
	pushd build;\
	cmake ../schism/src; \
	printf -v opts " %s" "$${opts[@]}";\
	eval "cmake ../schism/src $${opts}";\
	make -j $$(nproc) --no-print-directory

install:
	@set -e;\
	mkdir -p ${DESTDIR};\
	cp -r build/bin ${DESTDIR}/;\
	if command -v module &> /dev/null; \
	then \
		make modulefiles --no-print-directory;\
	fi

modulefiles:
	@set -e;\
	prefix=$${HOME}/.local/Modules/modulefiles/schism;\
	mkdir -p $${prefix};\
	modulefile=$${prefix}/${BRANCH};\
	echo '#%Module1.0' > $${modulefile};\
	echo '#' >> $${modulefile};\
	echo '# SCHISM ${BRANCH} tag' >> $${modulefile};\
	echo '#' >> $${modulefile};\
	echo '' >> $${modulefile};\
	echo 'proc ModulesHelp { } {' >> $${modulefile};\
	echo "puts stderr \"SCHISM loading from ${BRANCH} branch from a local compile @ ${DESTDIR}.\"" >> $${modulefile};\
	echo '}' >> $${modulefile};\
	echo "prepend-path PATH {${DESTDIR}/bin}" >> $${modulefile}



sciclone:
	@set -e;\
	source /usr/local/Modules/default/init/sh;\
	module purge;\
	module load intel/2018 intel/2018-mpi netcdf/4.4.1.1/intel-2018 netcdf-fortran/4.4.4/intel-2018 cmake;\
	make --no-print-directory;\
	mkdir -p ${DESTDIR};\
	cp -r build/bin ${DESTDIR}/;\
	prefix=$${HOME}/.local/Modules/modulefiles/schism/;\
	mkdir -p $${prefix};\
	modulefile=$${prefix}/${BRANCH};\
	echo '#%Module1.0' > $${modulefile};\
	echo '#' >> $${modulefile};\
	echo '# SCHISM ${BRANCH}' >> $${modulefile};\
	echo '#' >> $${modulefile};\
	echo '' >> $${modulefile};\
	echo 'proc ModulesHelp { } {' >> $${modulefile};\
	echo "puts stderr \"SCHISM loading from ${BRANCH} from a local compile @ ${DESTDIR}.\"" >> $${modulefile};\
	echo '}' >> $${modulefile};\
	echo 'if { [module-info mode load] && ![is-loaded intel/2018] } { module load intel/2018 }' >> $${modulefile};\
	echo 'if { [module-info mode load] && ![is-loaded intel/2018-mpi] } { module load intel/2018-mpi }' >> $${modulefile};\
	echo 'if { [module-info mode load] && ![is-loaded netcdf/4.4.1.1/intel-2018] } { module load netcdf/4.4.1.1/intel-2018 }' >> $${modulefile};\
	echo 'if { [module-info mode load] && ![is-loaded netcdf-fortran/4.4.4/intel-2018] } { module load netcdf-fortran/4.4.4/intel-2018 }' >> $${modulefile};\
	echo "prepend-path PATH {${DESTDIR}/bin}" >> $${modulefile}

clean:
	rm -rf ${MAKEFILE_PARENT}build




