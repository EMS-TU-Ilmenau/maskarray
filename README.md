# Layoutdatenstruktur

** As seen on Floating-Sparse-ghetti-monster Hackathon 2019 **

This repository contains a python module exposing the class `maskarray` for
the efficient representation of binary (on-off) process masks, specifically
designed with automization of ASIC layout mask data in mind.

### Main features are:
 - Import of mask data from (multiple) same-size pixel data images (.png, .bmp)
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
code/ -- implementation and pip installer
```
