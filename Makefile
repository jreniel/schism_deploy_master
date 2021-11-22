
default:
	@set -e;\
	rm -rf schism;\
	git clone https://github.com/schism-dev/schism;\
	mkdir build;\
	cd build;\
	cmake ../schism/src \
	-DNetCDF_Fortran_LIBRARY=$$(nf-config --prefix)/lib/libnetcdff.so \
	-DNetCDF_INCLUDE_DIRS=$$(nc-config --includedir) \
	-DNetCDF_C_LIBRARY=$$(nc-config --prefix)/lib/libnetcdf.so;\
	make -j$$(nproc)

modulefiles:
	@set -e;\
	PREFIX=$${HOME}/.local/Modules/modulefiles/schism;\
	mkdir -p $${PREFIX};\
	echo '#%Module1.0' > $${PREFIX}/master;\
	echo '#' >> $${PREFIX}/master;\
	echo '# SCHISM master tag' >> $${PREFIX}/master;\
	echo '#' >> $${PREFIX}/master;\
	echo '' >> $${PREFIX}/master;\
	echo 'proc ModulesHelp { } {' >> $${PREFIX}/master;\
	echo "puts stderr \"SCHISM loading from master branch from a local compile @ $${INSTALL_PATH}.\"" >> $${PREFIX}/master;\
	echo '}' >> $${PREFIX}/master;\
	echo "prepend-path PATH {${MAKEFILE_PARENT}/bin}" >> $${PREFIX}/master



sciclone:
	@set -e;\
	source /usr/local/Modules/default/init/sh;\
	module load intel/2018 intel/2018-mpi netcdf/4.4.1.1/intel-2018 netcdf-fortran/4.4.4/intel-2018 cmake;\
	make --no-print-directory;\
	mkdir -p sciclone/modulefiles/schism;\
	mv build/bin sciclone/bin;\
	echo '#%Module1.0' > sciclone/modulefiles/schism/master;\
	echo '#' >> sciclone/modulefiles/schism/master;\
	echo '# SCHISM master tag' >> sciclone/modulefiles/schism/master;\
	echo '#' >> sciclone/modulefiles/schism/master;\
	echo '' >> sciclone/modulefiles/schism/master;\
	echo 'proc ModulesHelp { } {' >> sciclone/modulefiles/schism/master;\
	INSTALL_PATH=$$(realpath sciclone/bin);\
	echo "puts stderr \"SCHISM loading from master branch from a local compile @ $${INSTALL_PATH}.\"" >> sciclone/modulefiles/schism/master;\
	echo '}' >> sciclone/modulefiles/schism/master;\
	echo 'if { [module-info mode load] && ![is-loaded intel/2018] } { module load intel/2018 }' >> sciclone/modulefiles/schism/master;\
	echo 'if { [module-info mode load] && ![is-loaded intel/2018-mpi] } { module load intel/2018-mpi }' >> sciclone/modulefiles/schism/master;\
	echo 'if { [module-info mode load] && ![is-loaded netcdf/4.4.1.1/intel-2018] } { module load netcdf/4.4.1.1/intel-2018 }' >> sciclone/modulefiles/schism/master;\
	echo 'if { [module-info mode load] && ![is-loaded netcdf-fortran/4.4.4/intel-2018] } { module load netcdf-fortran/4.4.4/intel-2018 }' >> sciclone/modulefiles/schism/master;\
	echo "prepend-path PATH {$${INSTALL_PATH}}" >> sciclone/modulefiles/schism/master;\
	mv build sciclone;\
	mkdir -p $${HOME}/.local/Modules/modulefiles/schism;\
	cp sciclone/modulefiles/schism/master $${HOME}/.local/Modules/modulefiles/schism/




