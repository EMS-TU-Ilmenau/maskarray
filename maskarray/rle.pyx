# -*- coding: utf-8 -*-

# Copyright 2019, Christoph Wagner
#    https://www.tu-ilmenau.de/it-ems/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from libc.string cimport memset
from libc.math cimport isnan

import numpy as np
cimport numpy as np

# initialize numpy C-API interface for cython extension-type classes.
# This call is required once for every module that uses PyArray_ calls
# WARNING: DO NOT REMOVE THIS LINE OR SEGFAULTS ARE ABOUT TO HAPPEN!
np.import_array()

#cdef CHUNK_INCREMENT = 256

################################################## encode_run_length
cpdef np.ndarray encode_run_length(np.ndarray array):
    r"""Perform run length encoding on data set

    Parameters
    ----------
    array : :py:class:`numpy.ndarray`
        Vector (1D) or array (2D) to be run length encoded. Data width must be
        1 byte. If an array is given, a row break symbol will be inserted into
        the data stream at the end of every row

    Returns
    -------
    :py:class:`numpy.ndarray`
        A vector containing the encoded symbol stream. If an array was given
        the symbol stream will contain one row break symbol at the end of each
        row.
    """
    cdef np.intp_t ii, rr = 0
    cdef np.int8_t *base = NULL
    cdef np.int8_t *pos = NULL
    cdef np.int8_t *end = NULL
    cdef np.int8_t *max = NULL
    cdef np.int8_t *start = NULL
    cdef bint run_type = False
    cdef np.int32_t symbol = 0
    cdef Mask_Pair_16_t pair
    cdef list lstOut = []

    # make sure the vector is 1D, contiguous and of int8 data type
    if array.ndim > 2:
        raise ValueError("Array argument must be 1D or 2D")

    array = np.ascontiguousarray(array, dtype=np.int8)

    # now crawl through that thing
    cdef np.intp_t num_rows = array.shape[0] if array.ndim > 1 else 1
    cdef np.ndarray vec_chunk = np.empty((CHUNK_INCREMENT, ), dtype=np.uint32)
    ii = 0
    base = <np.int8_t *> array.data
    for rr in range(num_rows):
        pos = &(base[rr * array.strides[0]]) if array.ndim > 1 else base
        end = &(pos[array.shape[1 if array.ndim > 1 else 0]])
        while pos < end:
            # crawl for runs of bits similar to bit at current position
            start = pos
            run_type = start[0] != 0

            # get a maximum pointer value, clipped by `end` and overflow-free
            max = (pos + MAX_SYMBOL_LENGTH
                   if end - pos > MAX_SYMBOL_LENGTH else end)

            # now walk the data to see how long the target value is met
            while (pos < max) and ((pos[0] != 0) == run_type):
                pos = pos + 1

            symbol = pos - start
            if run_type:
                vec_chunk[ii] = PAGE_ONES * PAGE_SIZE + symbol
            else:
                vec_chunk[ii] = PAGE_ZEROS * PAGE_SIZE + symbol

            # add symbol to output, and collect chunks of it
            ii = ii + 1
            if ii >= CHUNK_INCREMENT:
                lstOut.append(vec_chunk)
                vec_chunk = np.empty((CHUNK_INCREMENT, ), dtype=np.uint32)
                ii = 0

        vec_chunk[ii] = PAGE_ROWBREAK
        ii = ii + 1
        if ii >= CHUNK_INCREMENT:
            lstOut.append(vec_chunk)
            vec_chunk = np.empty((CHUNK_INCREMENT, ), dtype=np.uint32)
            ii = 0

    # trunc the latest chunk and add it to the output list
    if ii == CHUNK_INCREMENT:
        lstOut.append(vec_chunk)
    elif ii > 0:
        lstOut.append(vec_chunk[:ii])

    # finally, merge all outputs together
    return np.hstack(lstOut)

################################################## encode_run_length
cpdef np.ndarray substitute_symbols(
    np.ndarray stream, np.ndarray substitute
):
    r"""Substitute selected pairs of symbols by one symbol.

    Parameters
    ----------
    stream : :py:class:`numpy.ndarray`
        Vector holding the stream of symbols. Must be 1D, contiguous and of
        type uint32_t.

    substitute : :py:class:`numpy.ndarray`
        Vector describing the possible substitutions within the stream
        array. Must be of same shape as `stream`. Every non-zero entry in
        this array marks the corresponding entry of same index in `stream`
        and the one immediately following it for substitution by the value
        in `substitute` of that index.

    Returns
    -------
    :py:class:`numpy.ndarray`
        A new stream vector with the context substitution applied. The
        length of this vector depends on the contents of both input vectors
        as not all substitutions can always be applied.
    """

    # make sure the vector is 1D, contiguous and of int8 data type
    if (stream.ndim != 1) or (substitute.ndim != 1):
        raise ValueError("Vector arguments must be 1D")

    if (stream.dtype != np.uint32) or (substitute.dtype != np.uint32):
        raise TypeError("Vector arguments must be of type uint32")

    # make sure the input and substitution streams are contiguous
    stream = np.ascontiguousarray(stream)
    substitute = np.ascontiguousarray(substitute)

    cdef np.ndarray arr_out = np.empty_like(stream)
    cdef np.uint32_t *in_pos = <np.uint32_t *> stream.data
    cdef np.uint32_t *in_end = in_pos + stream.shape[0]
    cdef np.uint32_t *sub_pos = <np.uint32_t *> substitute.data
    cdef np.uint32_t *sub_end = <np.uint32_t *> sub_pos + substitute.shape[0]
    cdef np.uint32_t *out_pos = <np.uint32_t *> arr_out.data

    while in_pos < in_end:
        if sub_pos >= sub_end:
            out_pos[0] = in_pos[0]
        elif sub_pos[0] != SUBSTITUTE_SKIP:
            out_pos[0] = sub_pos[0]
            sub_pos += 2
            in_pos += 1
        else:
            out_pos[0] = in_pos[0]
            sub_pos += 1

        in_pos += 1
        out_pos += 1

    arr_out.resize((<np.intp_t> (out_pos - <np.uint32_t *> arr_out.data), ))

    return arr_out
