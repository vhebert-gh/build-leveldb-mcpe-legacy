Static build of [leveldb-mcpe](https://github.com/Mojang/leveldb-mcpe)
for 64-bit Windows.

# Building
Run `build.cmd` to compile locally. Ensure that you have the required
dependencies installed. See beginning of `build.cmd` for more information.

# Details
[leveldb-mcpe](https://github.com/Mojang/leveldb-mcpe) is a fork of Google's
[leveldb](https://github.com/google/leveldb) with added support for
[zlib](https://www.zlib.net/). This fork is used for the world storage format
for minecraft bedrock edition.

Other compression formats are present in this fork. However due to their lack of
use in bedrock edition they are excluded from this build.

This fork of leveldb is **only** intended to be used for interacting with minecraft
worlds generated from bedrock edition.

# Usage
Using leveldb-mcpe is very similar to using leveldb. The main difference is
that you must set the compression option to `leveldb_zlib_raw_compression`
when opening a database in order to read data from bedrock worlds. 

The following is a basic example of how to use the C based api exposed by
leveldb-mcpe:
```c
#include <leveldb\c.h>
#include <stdio.h>

int main()
{
	// Supply your path here.
	const char* DatabaseDir = "";

    	// Basic database types.
	leveldb_t* Database;
	leveldb_options_t* Options;
	
	// Required for error checking on all database operations.
	char* Status = NULL;

    	// Create config for our database.
	Options = leveldb_options_create();
	leveldb_options_set_create_if_missing(Options, 1);
	
	// Needed to read bedrock world data.
	leveldb_options_set_compression(Options, leveldb_zlib_raw_compression);
	
	// Open world.
	Database = leveldb_open(Options, DatabaseDir, &Status);
	
	// We need these to read and write to the database.
	leveldb_readoptions_t* ReadOptions = leveldb_readoptions_create();
	leveldb_writeoptions_t* WriteOptions = leveldb_writeoptions_create();
	
	// Uncomment to use synchronous writes. 
	//leveldb_writeoptions_set_sync(WriteOptions, 1);
	
	// Create iterator to loop through the entire database.
	leveldb_iterator_t* Iter = leveldb_create_iterator(Database, ReadOptions);
	for (leveldb_iter_seek_to_first(Iter); leveldb_iter_valid(Iter); leveldb_iter_next(Iter))
	{
		size_t KeyLength, ValueLength;
		const char* Key = leveldb_iter_key(Iter, &KeyLength);
		const char* Value = leveldb_iter_value(Iter, &ValueLength);
		printf("Key length: %zu, Value Length %zu\n", KeyLength, ValueLength);
	}
	
	// Destory the iterator.
	// This must be done before closing a database, otherwise an assertion is thrown.
	leveldb_iter_destroy(Iter);
	
	// Close the database.
	leveldb_close(Database);
	
	return 0;
}
```