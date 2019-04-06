# `maskarray` -- Efficient layout mask handling in Python

** As seen on Floating-Sparse-ghetti-monster Hackathon 2019 **

The python module `maskarray` enables the efficient representation of binary
(on-off) process masks, as found in many EDA fields, specifically
designed with automization of ASIC layout mask data in mind.

### Main features are:
 - Import of mask data from (multiple) same-size pixel data images (.png, .bmp)
 - Import mask data from ndarray (2D or 3D)
 - Optional image data transposition during import
 - Efficient storage in row-based Run-Length-Encoding
 - Tracking of spatial embedding information (resolution and origin)
 - Indexing either spatially (float-indices) or ordinal (int-indices)
 - Extraction of an arbitrary subset of data (along X-, Y-, Layer-dimensions)
   via the slicing interface of a_maskarray[xslice, yslice, layerslice]
 - Iterate parametrically with specification of iterator size over subsets
   ```python
   for row in a_maskarray(height=0.03):
      for window in a_maskarray(width=0.03):
         # window has dimensions of 0.03 x 0.03 reference units
   ```
 - Save/Load the format to/from disk
 - Hash the data for each stored layer
 - The data is immutable by design and can be converted to a dense ndarray

### Structure

```
docs/ -- specification via plantUML
maskarray/ -- implementation
/ - README, pip installer (setup.py)
```

## Usage

NOTE: `maskarray` uses cython to compile some performance-critical stuff
and link it in back to the python world. If you like to distribute the
resulting binaries you want to compile the package with a generic set of
compiler options to ensure it won't segfault on systems with a lesser set of
processor extensions than you have compiled it for on your machine. In that
case set the environment variable `MASKARRAY_GENERIC=1` before compilation.

### Installation

Simply run `pip install .` after checkout. The `maskarray` package will be
available after installation. Alternatively if you feel your heart lives for
`GNU make` after all you may also decide to hit `make install`

### Local build

Just for testing pursposes during development consider `make compile`. This
will trigger a complete build in this local directory and does not install
the produced result into your package repository. The module then will only
be available from within the root directory.

### Build documentation

`maskarray` contains a class documentation driven by `sphinx:numpy_doc`. To
rebuild the documentation run `make doc` in the main project directory. A
HTML documentation will be generated in the `doc/` directory.

### Style checks

Consistency is important! Therefore remember to check the things you type
fulfill at least the minimal standards, i.e. for that repository I chose
`PEP8` to be that kind of minimal standard.

NOTE: requires `pycodestyle` installed.
