module Tag.Model exposing (Tag)


type alias Tag =
    { tagId : String
    , name : String
    , contentCount : Int
    , infoContentId : Maybe Int
    }
