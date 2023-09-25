module Tag.Model exposing (Tag)


type alias Tag =
    { tagId : String
    , name : String
    , parentTags : List String
    , childTags : List String
    , contentCount : Int
    , infoContentId : Maybe Int
    }
