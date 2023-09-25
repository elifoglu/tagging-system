module DataResponse exposing (InitialDataResponse, ContentID, ContentSearchResponse, ContentsResponse, GotContent, GotContentDate, GotTag, initialDataResponseDecoder, contentDecoder, contentSearchResponseDecoder, contentsResponseDecoder, gotGraphDataDecoder)

import Content.Model exposing (GotGraphData, Ref, RefConnection)
import Json.Decode as D exposing (Decoder, field, int, map, map2, map3, map6, maybe, string)


type alias InitialDataResponse =
    { allTags : List GotTag, homeTagId: String }



type alias ContentsResponse =
    { totalPageCount : Int, contents : List GotContent }


type alias GotTag =
    { tagId : String
    , name : String
    , parentTags : List String
    , childTags : List String
    , contentCount : Int
    , infoContentId : Maybe Int
    }


type alias GotContent =
    { title : Maybe String, dateAsTimestamp : GotContentDate, contentId : Int, content : String, tags : List String, refs : List Ref, graphData : GotGraphData, furtherReadingRefs : List Ref }


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


contentsResponseDecoder : Decoder ContentsResponse
contentsResponseDecoder =
    map2 ContentsResponse
        (field "totalPageCount" int)
        (field "contents" (D.list contentDecoder))


contentSearchResponseDecoder : Decoder ContentSearchResponse
contentSearchResponseDecoder =
    map ContentSearchResponse
        (field "contents" (D.list contentDecoder))


gotGraphDataDecoder : Decoder GotGraphData
gotGraphDataDecoder =
    map3 GotGraphData
        (field "titlesToShow" (D.list string))
        (field "contentIds" (D.list int))
        (field "connections" (D.list refConnectionDecoder))


refConnectionDecoder : Decoder RefConnection
refConnectionDecoder =
    map2 RefConnection
        (field "a" int)
        (field "b" int)


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
    let
        decodeFirst6FieldAtFirst =
            map6 GotContent
                (maybe (field "title" string))
                (field "dateAsTimestamp" contentDateDecoder)
                (field "contentId" int)
                (field "content" string)
                (field "tags" (D.list string))
                (field "refs" (D.list refDecoder))
    in
    map3
        (<|)
        decodeFirst6FieldAtFirst
        (field "graphData" gotGraphDataDecoder)
        (field "furtherReadingRefs" (D.list refDecoder))


contentDateDecoder : Decoder GotContentDate
contentDateDecoder =
    D.string


refDecoder : Decoder Ref
refDecoder =
    map2 Ref
        (field "text" string)
        (field "id" string)