# -*- coding: utf-8 -*-

# Copyright 2019 Christoph Wagner
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

r"""
In the field of Electronic Design Automation (EDA) the design of process masks
is of central importance. These masks usually are binary (on or off) and
feature a resolution much higher than the smallest structure that are
represented within them. In practice this causes the masks to become very large
quickly with only limited information encoded in them when represented in any
kind of dense array structure (bitmaps or numeric arrays).

The `maskarray` package offers a class of same name that offers the means to
efficiently handle large sets of such masks by efficiently storing them in
memory and handling operations on them based on that compact memory
representation.
"""

# import fundamental types and classes first, also behavioural flags
from .maskarray import maskarray

# define package version (gets overwritten by setup script)
from .version import __version__
