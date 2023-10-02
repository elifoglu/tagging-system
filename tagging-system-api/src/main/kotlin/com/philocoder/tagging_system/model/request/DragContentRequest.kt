package com.philocoder.tagging_system.model.request

data class DragContentRequest(
    val tagTextViewType: String,
    val idOfDraggedContent: String,
    val idOfTagGroupThatDraggedContentBelong: String,
    val idOfContentToDropOn: String,
    val idOfTagGroupToDropOn: String,
    val dropToFrontOrBack: String,
    val idOfActiveTagPage: String
)