#!/usr/bin/env python3
# -------------------------------------------------------------------------------------------------
# <copyright file="precondition.pyd" company="Invariance Pte">
#  Copyright (C) 2018-2019 Invariance Pte. All rights reserved.
#  The use of this source code is governed by the license as found in the LICENSE.md file.
#  http://www.invariance.com
# </copyright>
# -------------------------------------------------------------------------------------------------

# cython: language_level=3, boundscheck=False, wraparound=False

cdef class Precondition(object):
    @staticmethod
    cdef true(bint predicate, unicode description)
    @staticmethod
    cdef is_none(object argument, unicode param_name)
    @staticmethod
    cdef not_none(object argument, unicode param_name)
    @staticmethod
    cdef valid_string(unicode argument, unicode param_name)
    @staticmethod
    cdef equal(object argument1, object argument2)
    @staticmethod
    cdef equal_lengths(
            list collection1,
            list collection2,
            str collection1_name,
            str collection2_name)
    @staticmethod
    cdef positive(double value, unicode param_name)
    @staticmethod
    cdef not_negative(double value, unicode param_name)
    @staticmethod
    cdef in_range(
            double value,
            str param_name,
            double start,
            double end)
    @staticmethod
    cdef not_empty(object argument, unicode param_name)
    @staticmethod
    cdef empty(object argument, unicode param_name)