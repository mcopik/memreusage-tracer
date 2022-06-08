

### Build Tool

To build the Pintool, you need to first download and unpack [Intel's PIN](https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-binary-instrumentation-tool-downloads.html).

Then, configure the build:

```
cmake -DCMAKE_INSTALL_PREFIX=<install-dir> -DPIN_ROOT=<pin-dir> ..
```

Then build and install the tool.

### Build Application

First, you need to specify instrumentation regions in your code:

```cpp

#include <memreuse.hpp>

__memreuse_roi_begin("foo");
__memreuse_roi_end("foo");
```

See the example in `examples/test.cpp`.

Extend your compilation flags with `-I<install-dir>/include` and linking flags with `-L<install-dir>/lib -lmemreuse`.

### Run Application

Run your application with:

```
<build-dir>/bin/memtracer -o tracer.out <your-app-with-arguments>
```

The files `tracer.out.{region}.{counter}` will contain the statistics on memory accesses for entered regions.

To run an MPI application with OpenMPI, use:

```
mpirun -np 2 <mpiflags> <build-dir>/bin/memtracer_ompi -o tracer.out <your-app-with-arguments>
```

The output for each MPI process will be in `tracer.{rank}.out.{region}.{counter}`.

### Postprocessing

Install Python dependencies:

```
pip install -r tools/requirements.txt
```

Then run the the postprocessing analysis by pointing to the directory and naming schemes of produced files:

```
tools/postprocessing.py <dir>/tracer.out <out-file>
```

After a while, the results will be written to the output file. For each iteration,
we compute the number of new memory regions that have been written or read:

```
,iteration,read_bytes,new_read_bytes,write_bytes,new_write_bytes
0,0,5052433,5052433,0,0
1,1,3371595,3371595,3177832,3177832
2,2,473686,15020,140083,21080
```


