module Content.Model exposing (Content, ContentDate)

import Date exposing (Date)
import Tag.Model exposing (Tag)


type alias Content =
    { title : Maybe String, createdAt : ContentDate, lastModifiedAt: ContentDate, isDeleted: Bool, contentId : String, text : String, tags : List Tag, tagIdOfCurrentTextPart: String }


type alias ContentID =
    Int


type alias ContentDate =
    Date
