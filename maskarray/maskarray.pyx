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

from .rle cimport *
from time import time

# initialize numpy C-API interface for cython extension-type classes.
# This call is required once for every module that uses PyArray_ calls
# WARNING: DO NOT REMOVE THIS LINE OR SEGFAULTS ARE ABOUT TO HAPPEN!
np.import_array()

################################################################################
################################################## class maskarray
cdef class maskarray(object):
    r"""maskarray base class


    **Description:**
    The baseclass for the maskarray package. Serves as container for mask
    layout data and implements all basic operations on layout data
    """
    def __init__(self):
        self.page_encoder = list()

    cpdef void add_layer(self, np.ndarray data):

        t1 = time()
        # stage 1: encode the pixel data into a runlength coded symbol stream
        cdef np.ndarray stream = encode_run_length(data)
        print("Encoded %d Pixels to %d symbols in %.2fs, rate: %.4f %%"% (
            data.size, stream.size, time() - t1,
            100. * stream.nbytes / data.nbytes
        ))

        # stage 2: apply iterated symbol substitution to compress the stream
        cdef np.intp_t len_begin = stream.size, len_before, len_after
        cdef np.intp_t cc = 0
        cdef np.intp_t pp = PAGE_FIRST_SYMBOL_TABLE
        while pp < PAGE_FIRST_ROW_TABLE:
            len_before = stream.size
            if cc < len(self.page_encoder):
                # there already exists an encoder object: apply it!
                t0 = time()
                stream = self.page_encoder[cc].encode(stream)
                pp = self.page_encoder[cc].page
                len_after = stream.size
                print("Encoder %d (page %d, %d symbols): %d -> %d in %.2fs" %(
                    cc, pp, self.page_encoder[cc].symbols.size,
                    len_before, len_after, time() - t0
                ))
            else:
                # create a new page and add it if it could compress something
                coder = substitution_encoder(pp)
                t0 = time()
                stream_new = coder.encode(stream)
                len_after = stream_new.size
                if len_after < len_before:
                    self.page_encoder.append(coder)
                    stream = stream_new
                    print(("Encoder %d (new page %d, %d symbols): " +
                           "%d -> %d in %.2fs") %(
                        cc, pp, self.page_encoder[cc].symbols.size,
                        len_before, len_after, time() - t0
                    ))
                else:
                    break

            cc += 1
            pp += 1

        print("Symbol coding completed in %.2fs: %d -> %d (%.2f %%) " %(
            time() - t1, len_begin, len_after, 100. * len_after / len_begin
        ))

        # stage 3: detect common rows
        # determine layout of rows in data
        t0 = time()
        cdef np.ndarray row_ends = np.where(stream == 0)[0]
        cdef np.ndarray row_starts = np.empty_like(row_ends)
        row_starts[0] = 0
        row_starts[1:] = row_ends[:-1] + 1
        # compute hashes of every row's data. For this stream must be read-only
        stream.flags.writeable = False
        cdef np.ndarray row_hashes = np.empty_like(row_ends, dtype=np.uint64)
        cdef np.intp_t ii
        for ii in range(row_hashes.shape[0]):
            row_hashes[ii] = hash(stream[row_starts[ii]:row_ends[ii]].data)
        # determine recurring hashes and where those groups are distributed
        cdef np.ndarray hash_map = np.unique(row_hashes, return_inverse=True)[1]
        # take the coarse grouping and perform exact matching within all groups
        # assign a unique ID for each matched row
        cdef list row_symbols = []
        cdef np.ndarray row_map = np.full_like(hash_map, -1, dtype=np.intp)
        cdef np.intp_t row_id, oo, start, end, ii_len
        cdef np.uint32_t *pos_a
        cdef np.uint32_t *end_a
        cdef np.uint32_t *pos_b
        cdef np.ndarray others
        ii = 0
        while ii < row_map.shape[0]:
            # already matched this row? then skip it and save some size!
            if row_map[ii] > -1:
                ii += 1
                continue

            # add this row to the output stream (it's something new!)
            row_id = len(row_symbols)
            row_symbols.append(stream[row_starts[ii]:row_ends[ii] + 1])
            row_map[ii] = row_id
            # now look for others rows
            others = np.where(hash_map == hash_map[ii])[0]
            others = others[others > ii]
            start = row_starts[ii]
            end = row_ends[ii]
            ii_len = end - start
            pos_a = &(<np.uint32_t *> stream.data)[start]
            end_a = &(<np.uint32_t *> stream.data)[end + 1]
            for oo in others:
                # if lengths differ we already know our fate before looking
                start = row_starts[oo]
                end = row_ends[oo]
                if end - start != ii_len:
                    continue

                # now let's compare!
                pos_b = &(<np.uint32_t *> stream.data)[start]
                while pos_a < end_a:
                    if pos_a[0] != pos_b[0]:
                        break

                    pos_a += 1
                    pos_b += 1

                if pos_a == end_a:
                    row_map[oo] = row_id

            ii += 1

        self.data = np.hstack(row_symbols)
        self.rows = row_map

        print("Row coding (%d unique rows of %d): %d -> %d in %.2fs" %(
            len(row_symbols), row_map.size, stream.size, self.data.size,
            time() - t0
        ))

        cdef np.intp_t total_size = self.data.nbytes + self.rows.nbytes
        for cc in range(len(self.page_encoder)):
            total_size += self.page_encoder[cc].symbols.nbytes

        print(("Coding completed in %.2fs: %d -> %d Bytes, Ratio: %.4f %%") %(
            time() - t1, data.nbytes, total_size,
            100. * total_size / data.nbytes
        ))


################################################################################
################################################## class symbolpage
cdef class substitution_encoder(object):

    def __init__(self, np.uint8_t page):
        self.page = page
        self.symbols = np.empty(2, dtype=np.uint64)
        self.symbols[0] = 0x010000c300000006
        self.symbols[1] = 0x01000008000004fd

    cpdef np.ndarray encode(self, np.ndarray stream):
        r"""Encode a data stream by applying and extending a set of known
        symbol replacements.

        Parameters
        ----------
        stream : :py:class:`numpy.ndarray`
            The data stream as 1D numpy array of type `uint32` containing valid
            symbols. First, the number of occurances of all pairs of symbols
            found within the given data stream will be determined. If any
            symbol pair occurs more than two times in the data stream it will
            be considered for substitution. All symbols pairs that are already
            known to this encoder will be marked for substitution by the
            replacement symbol as registered to this table. All the remaining
            symbols occuring sufficiently often, and being yet unknown to the
            encoder, will be assigned new symbol tokens and added to the symbol
            substitution set of the encoder.
            Finally, the determined substitution mapping will be applied to the
            data stream.

        Returns
        -------
        :py:class:`numpy.ndarray`
            A 1D array containing the new (compressed) data stream will be
            returned. If some sort of compression could be applied successfully
            the stream returned will be shorter than the input.
        """

        cdef np.ndarray stream_selection
        cdef np.ndarray substitute_symbol
        cdef np.ndarray context_symbols
        cdef np.ndarray symbols_insert

        # make sure the vector is 1D, contiguous and of int8 data type
        if (stream.ndim != 1):
            raise ValueError("Stream vector must be 1D")

        if (stream.dtype != np.uint32):
            raise TypeError("Stream vector must be of type uint32")

        # transform symbol stream into a chain of contexts (a `symbol diff`)
        cdef np.ndarray stream_context = stream[1:].astype(np.uint64)
        stream_context.view(dtype=('u4', 'u4'))[1::2] = stream[:-1]

        # determine the contexts appearing sufficiently often enough in stream
        cdef np.ndarray context, context_inverse, context_counts
        context, context_inverse, context_counts = np.unique(
    		stream_context, return_inverse=True, return_counts=True
    	)

        # select the contexts to be considered. Explicitly exclude contexts
        # with too few occurances and contexts containing a row break symbol
        cdef np.ndarray context_split = context.view(dtype=('u4', 'u4'))
        cdef np.ndarray context_selection = np.logical_and(
            context_counts >= MIN_OCCURANCES,
            np.logical_and(
                context_split[1::2] != PAGE_ROWBREAK,
                context_split[::2] != PAGE_ROWBREAK
            )
        )

    	# extract the set of contexts to be replaced in the stream
        cdef np.ndarray substitute_context = context[context_selection]

        # now see if we already have some of those contexts in our table
        # First, check if our sorting index is up to date. If not, resort it!
        cdef np.ndarray symbols_inverse = np.argsort(self.symbols)

        # determine where in our symbol table the context elements that have
        # been selected for stream replacement could already be present
        cdef np.ndarray substitute_closest = np.searchsorted(
            self.symbols, substitute_context, sorter=symbols_inverse
        )

        # now check which of those symbols are in the coding table
        cdef np.ndarray substitute_known = np.zeros_like(
            substitute_context, dtype=np.bool
        )
        cdef np.uint8_t *substitute_known_p = (
            <np.uint8_t *> substitute_known.data
        )
        cdef np.intp_t *substitute_closest_p = (
            <np.intp_t *> substitute_closest.data
        )
        cdef np.intp_t *substitute_context_p = (
            <np.intp_t *> substitute_context.data
        )
        cdef np.intp_t *symbols_p = <np.intp_t *> self.symbols.data
        cdef np.intp_t *symbols_inv_p = <np.intp_t *> symbols_inverse.data

        cdef np.intp_t ii, num_symbols = self.symbols.shape[0]
        for ii in range(substitute_known.shape[0]):
            if substitute_closest_p[0] < num_symbols:
                substitute_known_p[0] = symbols_p[
                    symbols_inv_p[substitute_closest_p[0]]
                ] == substitute_context_p[0]
            substitute_known_p += 1
            substitute_closest_p += 1
            substitute_context_p += 1

        # also extract a set of symbols to be added
        cdef np.ndarray context_known = substitute_context[substitute_known]
        cdef np.ndarray context_new = substitute_context[~substitute_known]
        cdef np.uint32_t offset = PAGE_SIZE * self.page + num_symbols
        cdef np.ndarray symbols_new = np.arange(
            offset, offset + context_new.shape[0]
        )
        cdef np.ndarray symbols_known = (
            symbols_inverse[substitute_closest[substitute_known]]
        )

        # add those new symbols to the encode symbol table. But only after
        # checking if we have enough space left
        cdef np.intp_t num_new_symbols = symbols_new.shape[0]
        if self.symbols.shape[0] >= MAX_SYMBOL_LENGTH:
            # the table is already full, so forget about all new symbols
            symbols_new = np.zeros_like(symbols_new)
        else:
            if self.symbols.shape[0] + num_new_symbols > MAX_SYMBOL_LENGTH:
                # the table is almost full and now we are going to stuff it
                num_new_symbols = (MAX_SYMBOL_LENGTH - self.symbols.shape[0] -
                                   symbols_new.shape[0])
                symbols_new[num_new_symbols:] = 0
                self.symbols = np.hstack(
                    (self.symbols, context_new[:num_new_symbols])
                )
            else:
                # enough space: add 'em all!
                self.symbols = np.hstack((self.symbols, context_new))


        # now let's determine substitution symbols for all our contexts
        cdef np.ndarray symbols = np.empty_like(
            substitute_context, dtype=np.uint32
        )
        symbols[substitute_known] = symbols_known
        symbols[~substitute_known] = symbols_new

        # and apply them into our full context set (using our selection array)
        cdef np.ndarray stream_substitute = np.full_like(
            context, SUBSTITUTE_SKIP, dtype=np.uint32
        )
        stream_substitute[context_selection] = symbols

        # finally, substitute the stream symbols
        cdef np.ndarray stream_replace = stream_substitute[context_inverse]

#        print(stream_context)
#        print(context_selection)
#        print(context)
#        print(context_split)
#        print(context_counts)
#        print(context_inverse)
#        print(substitute_context)
#        print(self.symbols)
#        print(symbols_inverse)
#        print(substitute_closest)
#        print(substitute_known)
#        print(context_known)
#        print(symbols_known)
#        print(context_new)
#        print(symbols_new)
#        print(symbols)
#        print(stream_substitute)
#        print(stream_replace)
#        print(num_new_symbols)

        return substitute_symbols(stream, stream_replace)
