package com.philocoder.tagging_system.model.response

data class InitialDataResponse(
    val allTags: List<TagResponse>,
    val homeTagId: String
)