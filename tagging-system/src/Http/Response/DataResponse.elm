module DataResponse exposing (InitialDataResponse, ContentID, ContentSearchResponse, TagDataResponse, GotContent, GotContentDate, GotTag, initialDataResponseDecoder, contentDecoder, contentSearchResponseDecoder, tagDataResponseDecoder)

import Json.Decode as D exposing (Decoder, field, int, map, map2, map5, map6, maybe, string)


type alias InitialDataResponse =
    { allTags : List GotTag, homeTagId: String }



type alias TagDataResponse =
    { contents : List GotContent
    , condensedContentText : String }


type alias GotTag =
    { tagId : String
    , name : String
    , parentTags : List String
    , childTags : List String
    , contentCount : Int
    , infoContentId : Maybe Int
    }


type alias GotContent =
    { title : Maybe String, dateAsTimestamp : GotContentDate, contentId : Int, content : String, tags : List String }


type alias ContentID =
    Int


type alias GotContentDate =
    String


type alias ContentSearchResponse =
    { contents : List GotContent
    }


initialDataResponseDecoder : Decoder InitialDataResponse
initialDataResponseDecoder =
    map2 InitialDataResponse
        (field "allTags" (D.list tagDecoder))
        (field "homeTagId" string)


tagDataResponseDecoder : Decoder TagDataResponse
tagDataResponseDecoder =
    map2 TagDataResponse
        (field "contents" (D.list contentDecoder))
        (field "condensedContentText" string)


contentSearchResponseDecoder : Decoder ContentSearchResponse
contentSearchResponseDecoder =
    map ContentSearchResponse
        (field "contents" (D.list contentDecoder))


tagDecoder : Decoder GotTag
tagDecoder =
    map6 GotTag
        (field "tagId" string)
        (field "name" string)
        (field "parentTags" (D.list string))
        (field "childTags" (D.list string))
        (field "contentCount" int)
        (field "infoContentId" (maybe int))


contentDecoder : Decoder GotContent
contentDecoder =
    map5 GotContent
        (maybe (field "title" string))
        (field "dateAsTimestamp" contentDateDecoder)
        (field "contentId" int)
        (field "content" string)
        (field "tags" (D.list string))



contentDateDecoder : Decoder GotContentDate
contentDateDecoder =
    D.string