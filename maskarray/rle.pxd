# -*- coding: utf-8 -*-

# Copyright 2019, Christoph Wagner
#     https://www.tu-ilmenau.de/it-ems/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import cython
import numpy as np
cimport numpy as np

cdef extern from "rle.h":
    #define MIN_OCCURANCES          3
    #define CHUNK_INCREMENT         0x1000
    #define MAX_SYMBOL_LENGTH       0xFFFFFF
    #define PAGE_SIZE               0x1000000

    #define PAGE_ROWBREAK           0x00000000
    #define SUBSTITUTE_SKIP         0x00000000

    #define PAGE_ZEROS              0x00
    #define PAGE_ONES               0x01
    #define PAGE_PATTERN            0x02
    #define PAGE_FIRST_SYMBOL_TABLE 0x03
    #define PAGE_FIRST_ROW_TABLE    0xFF
    cdef np.uint8_t MIN_OCCURANCES
    cdef np.uint32_t CHUNK_INCREMENT
    cdef np.uint32_t MAX_SYMBOL_LENGTH
    cdef np.uint32_t PAGE_SIZE
    cdef np.uint32_t PAGE_ROWBREAK
    cdef np.uint32_t SUBSTITUTE_SKIP

    cdef np.uint8_t PAGE_ZEROS
    cdef np.uint8_t PAGE_ONES
    cdef np.uint8_t PAGE_PATTERN
    cdef np.uint8_t PAGE_FIRST_SYMBOL_TABLE
    cdef np.uint8_t PAGE_FIRST_ROW_TABLE
"""r


"""

"""r
test
"""
ctypedef enum MASK_TYPE:
    MASK_TYPE_RESERVED
    MASK_TYPE_RUN4
    MASK_TYPE_RUN8
    MASK_TYPE_RUN16

"""r
:c:type::numpy.np.uint16_t zeros
:c:type::numpy.np.uint16_t ones
"""
cdef struct Mask_Pair_16_t:
    np.uint16_t ones
    np.uint16_t zeros

cdef struct Mask_Run_16_t:
    # four byte mask run container
    np.uint16_t zeros
    np.uint16_t ones

cdef struct Mask_Run_8_t:
    # two byte mask run container
    np.uint8_t zeros
    np.uint8_t ones

cdef struct Mask_Run_4_t:
    # one byte mask run container
    # zeros run length coded in high nibble of byte
    # ones run length coded in low bibble of byte
    np.uint8_t zeros_ones

cdef struct Mask_Segment_t:
    # container selector
    np.uint32_t offset
    np.uint8_t type
    np.uint8_t count
    np.uint8_t repeat
    np.uint8_t reserved

cpdef np.ndarray encode_run_length(np.ndarray)
cpdef np.ndarray substitute_symbols(np.ndarray, np.ndarray)
