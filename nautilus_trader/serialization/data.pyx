#!/usr/bin/env python3
# -------------------------------------------------------------------------------------------------
# <copyright file="data.pyx" company="Nautech Systems Pty Ltd">
#  Copyright (C) 2015-2019 Nautech Systems Pty Ltd. All rights reserved.
#  The use of this source code is governed by the license as found in the LICENSE.md file.
#  http://www.nautechsystems.io
# </copyright>
# -------------------------------------------------------------------------------------------------

# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False

import iso8601
import msgpack

from bson import BSON
from bson.raw_bson import RawBSONDocument
from decimal import Decimal

from nautilus_trader.model.objects cimport Symbol, Price, BarSpecification, Bar, Tick, Instrument, Quantity
from nautilus_trader.model.enums import Broker, Venue, Currency, OrderSide, OrderType, TimeInForce, SecurityType
from nautilus_trader.model.c_enums.venue cimport venue_string
from nautilus_trader.model.c_enums.brokerage cimport Broker, broker_string
from nautilus_trader.model.c_enums.time_in_force cimport TimeInForce, time_in_force_string
from nautilus_trader.model.c_enums.order_side cimport OrderSide, order_side_string
from nautilus_trader.model.c_enums.order_type cimport OrderType, order_type_string
from nautilus_trader.model.c_enums.currency cimport Currency, currency_string
from nautilus_trader.model.c_enums.security_type cimport SecurityType, security_type_string
from nautilus_trader.model.identifiers cimport InstrumentId
from nautilus_trader.serialization.base cimport InstrumentSerializer
from nautilus_trader.serialization.common cimport *
from nautilus_trader.serialization.keys cimport *


cpdef Tick deserialize_tick(Symbol symbol, bytes tick_bytes):
    """
    Return a parsed a tick from the given UTF-8 string.

    :param symbol: The ticks symbol.
    :param tick_bytes: The tick bytes to deserialize.
    :return: Tick.
    """
    cdef list values = tick_bytes.decode(UTF8).split(',')

    return Tick(
        symbol,
        Price(values[0]),
        Price(values[1]),
        iso8601.parse_date(values[2]))

cpdef Bar deserialize_bar(bytes bar_bytes):
    """
    Return the deserialized bar from the give bytes.
    
    :param bar_bytes: The bar bytes to deserialize.
    :return: Bar.
    """
    cdef list values = bar_bytes.decode(UTF8).split(',')

    return Bar(
        Price(values[0]),
        Price(values[1]),
        Price(values[2]),
        Price(values[3]),
        Quantity(values[4]),
        iso8601.parse_date(values[5]))

cpdef list deserialize_bars(bytes[:] bar_bytes_array):
    """
    Return a list of deserialized bars from the given bars bytes.
    
    :param bar_bytes_array: The bar bytes to deserialize.
    :return: List[Tick].
    """
    cdef list bars = []
    cdef int i
    cdef int array_length = len(bar_bytes_array)
    for i in range(array_length):
        bars.append(deserialize_bar(bar_bytes_array[i]))

    return bars


cdef class MsgPackInstrumentSerializer(InstrumentSerializer):
    """
    Provides an instrument serializer for the MessagePack specification.
    """

    cpdef bytes serialize(self, Instrument instrument):
        """
        Return the MessagePack specification bytes serialized from the given instrument.

        :param instrument: The instrument to serialize.
        :return: bytes.
        """
        return msgpack.packb({
            ID: instrument.id.value,
            SYMBOL: instrument.symbol.value,
            BROKER_SYMBOL: instrument.broker_symbol,
            QUOTE_CURRENCY: currency_string(instrument.quote_currency),
            SECURITY_TYPE: security_type_string(instrument.security_type),
            TICK_PRECISION: instrument.tick_precision,
            TICK_SIZE: str(instrument.tick_size),
            ROUND_LOT_SIZE: instrument.round_lot_size.value,
            MIN_STOP_DISTANCE_ENTRY: instrument.min_stop_distance_entry,
            MIN_STOP_DISTANCE: instrument.min_stop_distance,
            MIN_LIMIT_DISTANCE_ENTRY: instrument.min_limit_distance_entry,
            MIN_LIMIT_DISTANCE: instrument.min_limit_distance,
            MIN_TRADE_SIZE: instrument.min_trade_size.value,
            MAX_TRADE_SIZE: instrument.max_trade_size.value,
            ROLL_OVER_INTEREST_BUY: str(instrument.rollover_interest_buy),
            ROLL_OVER_INTEREST_SELL: str(instrument.rollover_interest_sell),
            TIMESTAMP: convert_datetime_to_string(instrument.timestamp),
        })

    cpdef Instrument deserialize(self, bytes instrument_bytes):
        """
        Return the instrument deserialized from the given MessagePack specification bytes.

        :param instrument_bytes: The bytes to deserialize.
        :return: Instrument.
        """
        cdef dict unpacked = msgpack.unpackb(instrument_bytes, raw=False)

        return Instrument(
            instrument_id=InstrumentId(unpacked[ID]),
            symbol=parse_symbol(unpacked[SYMBOL]),
            broker_symbol=unpacked[BROKER_SYMBOL],
            quote_currency=Currency[(unpacked[QUOTE_CURRENCY])],
            security_type=SecurityType[(unpacked[SECURITY_TYPE])],
            tick_precision=unpacked[TICK_PRECISION],
            tick_size=Decimal(unpacked[TICK_SIZE]),
            round_lot_size=Quantity(unpacked[ROUND_LOT_SIZE]),
            min_stop_distance_entry=unpacked[MIN_STOP_DISTANCE_ENTRY],
            min_stop_distance=unpacked[MIN_STOP_DISTANCE],
            min_limit_distance_entry=unpacked[MIN_LIMIT_DISTANCE_ENTRY],
            min_limit_distance=unpacked[MIN_LIMIT_DISTANCE],
            min_trade_size=Quantity(unpacked[MIN_TRADE_SIZE]),
            max_trade_size=Quantity(unpacked[MAX_TRADE_SIZE]),
            rollover_interest_buy=Decimal(unpacked[ROLL_OVER_INTEREST_BUY]),
            rollover_interest_sell=Decimal(unpacked[ROLL_OVER_INTEREST_SELL]),
            timestamp=convert_string_to_datetime(unpacked[TIMESTAMP]))


cdef class DataSerializer:
    """
    Provides a serializer for data objects.
    """

    cpdef object serialize_ticks(self, list ticks):
        """
        Serialize the given tick.
        
        :param ticks: The ticks to serialize.
        :return: RawBSONDocument.
        """
        return RawBSONDocument(BSON.encode({
            "Symbol": ticks[0].symbol.value,
            "Values": [str(tick) for tick in ticks]}))
