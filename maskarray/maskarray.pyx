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

################################################################################
################################################## class maskarray
cdef class maskarray(object):
    r"""maskarray base class


    **Description:**
    The baseclass for the maskarray package. Serves as container for mask
    layout data and implements all basic operations on layout data
    """
    pass
