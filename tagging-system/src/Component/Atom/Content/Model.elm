module Content.Model exposing (Content, ContentDate)

import Date exposing (Date)
import Tag.Model exposing (Tag)


type alias Content =
    { title : Maybe String, date : ContentDate, contentId : ContentID, text : String, tags : List Tag }


type alias ContentID =
    Int


type alias ContentDate =
    Date
