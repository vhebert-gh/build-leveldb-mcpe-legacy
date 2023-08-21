@echo off
setlocal EnableDelayedExpansion

set INSTAll=%~dp0build
set DEPENDENCIES=%~dp0dependencies

set ZLIB_VERSION=1.3
set LEVELDB_MCPE_COMMIT_HASH=278d5665

where.exe /Q curl.exe || (
	echo ERROR: curl.exe was not found.
	exit /B 1
)

where.exe /Q tar.exe || (
	echo ERROR: tar.exe was not found.
	exit /B 1
)

where.exe /Q cmake.exe || (
	echo ERROR: cmake.exe was not found.
	exit /B 1
)

where.exe /Q git.exe || (
	echo ERROR: git.exe was not found.
	exit /B 1
)

where.exe /Q cl.exe || (
	if not exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer" (
		echo ERROR: Visual Studio installation was not found.
		exit /B 1
	)

	for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath') do set VS=%%i

	if "!VS!" equ "" (
		echo ERROR: Visual Studio Native Desktop workload was not found.
		exit /B 1
	)
	call "!VS!\Common7\Tools\VsDevCmd.bat" -arch=amd64 -host_arch=amd64 -no_logo || exit /B 1
)

if not exist dependencies mkdir dependencies

pushd dependencies

if not exist zlib-%ZLIB_VERSION% (
	curl.exe -sfLO https://zlib.net/zlib-%ZLIB_VERSION%.tar.gz
	tar.exe -xf zlib-%ZLIB_VERSION%.tar.gz
)

cmake.exe -Wno-dev					^
	-S zlib-%ZLIB_VERSION%				^
	-B zlib-%ZLIB_VERSION%				^
	-DCMAKE_POLICY_DEFAULT_CMP0091=NEW		^
	-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded	^
	-DCMAKE_INSTALL_PREFIX=%DEPENDENCIES%\build	^
	|| exit /B 1
cmake.exe --build zlib-%ZLIB_VERSION% --config Release --target install --parallel || exit /B 1

git.exe clone --no-tags --single-branch https://github.com/Mojang/leveldb-mcpe

pushd leveldb-mcpe

git.exe checkout %LEVELDB_MCPE_COMMIT_HASH%

copy ..\..\mojang-leveldb.patch .

git.exe apply mojang-leveldb.patch || exit /B 1

set LEVELDB_MCPE_SRC=			^
	db\builder.cc 			^
        db\c.cc 			^
        db\dbformat.cc 			^
        db\db_impl.cc 			^
        db\db_iter.cc 			^
        db\dumpfile.cc 			^
        db\filename.cc 			^
        db\leveldbutil.cc 		^
        db\log_reader.cc 		^
        db\log_writer.cc 		^
        db\memtable.cc 			^
        db\repair.cc 			^
        db\table_cache.cc 		^
        db\version_edit.cc 		^
        db\version_set.cc 		^
        db\write_batch.cc 		^
        db\zlib_compressor.cc 		^
        helpers\memenv\memenv.cc 	^
        port\port_win.cc 		^
        port\port_posix_sse.cc 		^
        table\block.cc 			^
        table\block_builder.cc 		^
        table\filter_block.cc 		^
        table\format.cc 		^
        table\iterator.cc 		^
        table\merger.cc 		^
        table\table.cc 			^
        table\table_builder.cc 		^
        table\two_level_iterator.cc	^
        util\arena.cc 			^
        util\bloom.cc 			^
        util\cache.cc 			^
        util\coding.cc 			^
        util\comparator.cc 		^
        util\crc32c.cc 			^
        util\env.cc 			^
        util\env_win.cc 		^
        util\filter_policy.cc 		^
        util\hash.cc 			^
        util\histogram.cc 		^
        util\logging.cc 		^
        util\options.cc 		^
        util\status.cc 			^
        util\win_logger.cc

cl.exe /nologo %LEVELDB_MCPE_SRC% /c /EHsc /GR- /O2 -DOS_WIN /DLEVELDB_PLATFORM_WINDOWS -DWIN32 -DDLLX= /I. /I./include /I%DEPENDENCIES%\build\include
lib.exe /nologo *.obj /OUT:leveldb.lib /LIBPATH:%DEPENDENCIES%\build\lib zlibstatic.lib

mkdir %INSTALL%\include\leveldb %INSTALL%\lib
copy /y .\include\leveldb %INSTALL%\include\leveldb
copy /y leveldb.lib %INSTALL%\lib\leveldb.lib

popd

popd

if "%GITHUB_WORKFLOW%" neq "" (
	7z.exe a -y leveldb-mcpe-%LEVELDB_MCPE_COMMIT_HASH%.zip build\.
)