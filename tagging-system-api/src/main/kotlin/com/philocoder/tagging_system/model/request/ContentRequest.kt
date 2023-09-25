package com.philocoder.tagging_system.model.request

interface ContentRequest {
    val title: String?
    val text: String
    val tags: String
    val refs: String?
}