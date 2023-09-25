package com.philocoder.tagging_system.model.request

data class HomePageDataRequest(
    val page: Int = 1,
    val size: Int = 10000
)