

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

The file `tracer,out` will contain the statistics on memory accesses for entered regions.

To run an MPI application with OpenMPI, use:

```
mpirun -np 2 <mpiflags> <build-dir>/bin/memtracer_ompi -o tracer.out <your-app-with-arguments>
```

The output for each MPI process will be in `tracer.{rank}.out`.


