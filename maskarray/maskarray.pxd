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

from .rle cimport *

cdef class substitution_encoder(object):
    cdef readonly np.uint8_t page
    cdef readonly np.ndarray symbols
    cpdef np.ndarray encode(self, np.ndarray)


cdef class maskarray(object):
    cdef readonly list page_encoder
    cdef readonly np.ndarray data
    cdef readonly np.ndarray rows
    cpdef void add_layer(self, np.ndarray)
