package com.philocoder.tagging_system.model.request

interface ContentRequest {
    val title: String?
    val text: String
    val tagIds: List<String>
}