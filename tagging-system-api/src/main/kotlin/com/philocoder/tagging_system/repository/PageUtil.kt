package com.philocoder.tagging_system.repository

import java.util.*

object PageUtil {

    fun <T> getPage(sourceList: List<T>, page: Int, pageSize: Int): List<T> {
        require(!(pageSize <= 0 || page <= 0)) { "invalid page size: $pageSize" }
        val fromIndex = (page - 1) * pageSize
        return if (sourceList.size <= fromIndex) {
            Collections.emptyList()
        } else sourceList.subList(fromIndex, Math.min(fromIndex + pageSize, sourceList.size))
    }
}