package com.philocoder.tagging_system.util

import arrow.core.Option
import java.util.*

object ConversionUtils {

    val <T> Optional<T>.kt: T?
        get() = orElse(null)

    val <T> Optional<T>.arrow: Option<T>
        get() = Option.fromNullable(kt)

    val <T> T?.a: Option<T>
        get() = Option.fromNullable(this)
}