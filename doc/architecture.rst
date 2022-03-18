..  Copyright 2019 Christoph Wagner
        https://www.tu-ilmenau.de/it-ems/

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

.. _Architecture:

Architecture
===============

Motivation
----------

Layout data is usually represented by a binary (on/off) grid of high resolution in which the actual mask shapes are layed out. Limited by extensive sets of design rules the minimal feature width of any structure is usually many times larger than the grid resolution. This circumstance gives rise to the observation that image representations of layout layers are tremendously large but very good compressible at the same time. During design time this is circumvented by extensive use of vectorized representations. However in some applications a gridded representation is necessary or at least beneficial, such as in image processing and machine learning.

`maskarray` enables the compact representation of such gridded layout data in memory while maintaining an efficient computational interface for operations such as scaling, segmenting and convolutions.

Data model
----------

Any layered layout in process-mask-driven technologies can be represented as a three dimensional Tensor :math:`D \in \mathbb{B}^{N \times M \times L}`, where :math:`N` and :math:`M` represents the number of mask image rows and columns respectively, :math:`L` the number of layers of same dimensions and :math:`\mathbb{B}` is a set of two distinct values `{0, 1}` denoting any mask element at any position.

.. tikz:: Data model of a layout.

    \sffamily\huge
    \def\w{10}\def\h{5}\def\l{4}
    \foreach \ii in {0,...,\l} {
        \draw[fill=lightgray,draw=black,fill opacity=0.5] (\h, \ii) -- (0, \ii + \h) -- (\w, \ii + \h) -- (\w + \h, \ii) -- cycle;
    }
    \draw[-latex, thick] (-1, \h) -- (-1, \h + \l) node [left, pos=0.5] {$L$};
    \draw[-latex, thick] (0, \h + \l + 1) -- (\w, \h + \l + 1) node [above, pos=0.5] {$M$};
    \draw[-latex, thick] (-1, \h) -- (\h - 1, 0) node [left, pos=0.5] {$N$};


Data structure
--------------

As the layer resolution is usually much higher than the minimal structure size, a layer image consists of many runs of zeros and ones, thus rendering it highly compressible both along the :math:´N` rows or :math:`M` columns of each mask layer. In this work row encoding is employed, such that a layout may be represented by :math:`N \times L` encoded rows.

.. tikz:: Example of two rows in one layer of a gridded layout. The minimal structure width is four times the image resolution.

    \sffamily\huge
    \tikzstyle{mask}=[fill=gray, color=gray, thick]
    \draw[mask] (2,0)-|(6,12)-|(10,20)-|(6,16)-|cycle;
    \draw[mask] (10,0)|-(18,8)|-(14,16)|-(22,20)|-(14,4)|-cycle;
    \draw[mask] (26,0)-|(30,20)-|cycle;
    \draw[latex-latex, line width=4, color=white, text=white] (18,10)
            -- node [above] {4} (22,10);
    \newcommand\drawline[2]{\foreach [count=\ii] \bb in {#2,\large\dots}
        \filldraw[fill=white, draw=black, fill opacity=0.5, thick]
        (\ii - 1, #1) rectangle (\ii, #1 + 1) node[shift={(-0.5,-0.5)}, opacity=1] {\bb};
    }
    \drawline{6}{0,0,1,1,1,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,0}
    \drawline{16}{0,0,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,0}

As can be seen easily, the information of both rows can be stored by only encoding the run lengths of zeros and ones:

.. code-block::

    ROW 1: 2,4,4,12,4,4,1,...
    ROW 2: 2,8,8,4,4,4,0,...

Statistical observations
------------------------

Analyzing an example layout of 32 layers of size :math:`35681 \times 27611` some statistics are shown for three representative layers:

======================  ==========  ==========  ==========
Property                A           B           C
======================  ==========  ==========  ==========
Pixel fill ratio        3.9 %       35.1 %      50.0 %
Occupied row ratio      91.4 %      98.3 %      99.98 %
Max runs per row        1'759       440         385
Avg. runs per row       247         173         200
======================  ==========  ==========  ==========

======================  ==========  ==========  ==========
Runs of 1               A           B           C
======================  ==========  ==========  ==========
Total count in layer    6'243'143   4'696'337   5'508'570
Minimum                 6           5           6
Maximum                 7           12'475      23'676
Average                 6.2         73.6        89.4
Median                  6           9           53
Length < 16             100.0 %     53.5 %      34.4 %
Length of 16...255      None        44.0 %      62.2 %
Length of 256...4095    None        2.44 %      3.30 %
Length >= 4096          None        0.015 %     0.084 %
======================  ==========  ==========  ==========

======================  ==========  ==========  ==========
Runs of 0               A           B           C
======================  ==========  ==========  ==========
Total count in layer    6'243'143   4'696'337   5'508'570
Minimum                 3           5           6
Maximum                 34'553      33'048      32'318
Average                 119.5       121.5       84.6
Median                  14          6           10
Length < 16             66.3 %      70.3 %      66.7 %
Length of 16...255      30.0 %      24.2 %      28.6 %
Length of 256...4095    3.26 %      5.12 %      4.63 %
Length >= 4096          0.46 %      0.36 %      0.12 %
======================  ==========  ==========  ==========

==============================  ==========  ==========  ==========
0/1 pairs runlength categories  A           B           C
==============================  ==========  ==========  ==========
Size categories match           74.4 %      40.9 %      39.5 %
Mismatch of 1 size category     22.4 %      54.6 %      58.8 %
Mismatch of 2 size categories   3.05 %      4.35 %      1.66 %
Mismatch of 3 size categories   0.19 %      0.087 %     0.017 %
==============================  ==========  ==========  ==========

==============================  ==========  ==========  ==========
Streaks of category pairs       A           B           C
==============================  ==========  ==========  ==========
Same-cat. streak total          2'653'987   3'649'497   1'168'991
Same-cat. longest streak        2.35        1.29        4.71
Same-cat. average length        2.35        1.29        4.71
Adjacent-cat. streak total      280'781     146'655     121'199
Adjacent-cat. longest streak    1'759       440         385
Adjacent-cat. average length    22.2        32.0        39.6
==============================  ==========  ==========  ==========

Conclusions and Design considerations
-------------------------------------
The following observations can be concluded to design decisions for the run length coding representation of layout data:
 - Most runs are close to the minimal structure widths allowed
 - If a run of zeros is long, it is often very long
 - As most run lengths are rather small, but very large runs also occur, it is beneficial to employ variable coding of run length
 - Encoding run length as half bytes is beneficial
 - Optimal run length coding size changes frequently
 - Run length encoding is still quite similar over larger areas
 - If a small category size mismatch is allowed the size categories can be encoded much more efficiently by grouping them in segments
 - A maximum of 255 (fits into one byte) pair segments is sufficient to hold count informations
 - Segments can skip long intermediate zero areas by adding start indices. This would also improve search time into a row at relatively little coding size cost
 - Segments can store additional meta information in a container structure around it to allow walking more efficiently (double-referenced list)

Data structure
--------------

A layout is indexed over layers and rows. Each `row` contains coded pixel data and is divided into an arbitrarily sized list of segments, which encode the actual pixel stream in so called `pairs` of a run of ones and a run of zeros in that order, each determined fully by their respective run length. A pair thus always starts with a run of ones and ends with a run of zeros. Each segment can hold up to 255 of such pairs and defines the run length coding employed for all of the pairs in that segment. Valid coding sizes are half-byte, byte and word, resulting in a data structure size for one pair of one, two and four bytes respectively. If the amount of pixels encoded in one segment is smaller than the offset difference between that segment and the segment following directly after it, the resulting gap between these segments is considered to be zero.

The two rows shown in the example above can be coded in that scheme as follows:

.. code-block::

    ROW 1: consists of 1 segment
        SEGMENT 1 at offset 6:
            encoding 3 pairs of 1 byte each: [(4, 4), (8, 4), (4, 1)]

    ROW 2: consists of 1 segment
        SEGMENT 1 at offset 2:
            encoding 3 pairs of 1 byte each: [(4, 4), (12, 4), (4, 1)]


Each segment consists of a segment header of four bytes and pair data of variable length and is zero-padded to increments of four bytes to allow fast access to the data structures on most architectures. With this example the example would occupy 16 bytes of memory to encode both rows.

Pairs and Segments contains no positioning and reference information to allow their hashes to only contain information about their contents.

Each data structure either has a known

**Runs of Zeros and Ones**
  - bla
  - blub

.. c:type:: maskarray.rle.MASK_TYPE

.. c:type:: maskarray.rle.Mask_Run_16
.. c:type:: maskarray.rle.Mask_Run_8
.. c:type:: maskarray.rle.Mask_Run_4
.. c:type:: maskarray.rle.Mask_Segment

.. _`Examples`:

Examples
--------

Sample example:

>>> import maskarray as ma
>>> import numpy as np
