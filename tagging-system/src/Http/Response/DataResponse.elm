module DataResponse exposing (AllTagsResponse, BioGroupUrl, BioItemID, BioResponse, ContentID, ContentReadResponse, ContentSearchResponse, ContentsResponse, EksiKonserveException, EksiKonserveResponse, EksiKonserveTopic, GotBioGroup, GotBioItem, GotContent, GotContentDate, GotTag, HomePageDataResponse, allTagsResponseDecoder, bioResponseDecoder, contentDecoder, contentReadResponseDecoder, contentSearchResponseDecoder, contentsResponseDecoder, eksiKonserveResponseDecoder, gotGraphDataDecoder, homePageDataResponseDecoder)

import Content.Model exposing (GotGraphData, Ref, RefConnection)
import Json.Decode as D exposing (Decoder, bool, field, int, map, map2, map3, map4, map5, map6, map7, map8, maybe, string)


type alias AllTagsResponse =
    { allTags : List GotTag }


type alias HomePageDataResponse =
    { allTagsToShow : List GotTag
    }


type alias ContentsResponse =
    { totalPageCount : Int, contents : List GotContent }


type alias ContentReadResponse =
    { idOfReadContentOrErrorMessage : String
    , newTotalPageCountToSet : Int
    , contentToShowAsReplacementOnBottom : Maybe GotContent
    }


type alias GotTag =
    { tagId : String
    , name : String
    , contentCount : Int
    , infoContentId : Maybe Int
    }


type alias GotContent =
    { title : Maybe String, dateAsTimestamp : GotContentDate, contentId : Int, content : String, tags : List String, refs : List Ref, graphData : GotGraphData, furtherReadingRefs : List Ref }


type alias ContentID =
    Int


type alias GotContentDate =
    String


type alias BioResponse =
    { groups : List GotBioGroup
    , items : List GotBioItem
    }


type alias GotBioGroup =
    { url : String
    , title : String
    , displayIndex : Int
    , info : Maybe String
    , bioGroupId: Int
    , bioItemOrder : List Int
    }


type alias BioGroupUrl =
    String


type alias BioItemID =
    Int


type alias GotBioItem =
    { bioItemID : Int
    , name : String
    , groups : List Int
    , groupNames : List String
    , colorHex : Maybe String
    , info : Maybe String
    }


type alias ContentSearchResponse =
    { contents : List GotContent
    }


type alias EksiKonserveTopic =
    { name : String
    , url : String
    , count : Int
    }


type alias EksiKonserveException =
    { message : String
    , count : Int
    , timestamps : List String
    , show : Bool
    }


type alias EksiKonserveResponse =
    { topics : List EksiKonserveTopic
    , exceptions : List EksiKonserveException
    }


allTagsResponseDecoder : Decoder AllTagsResponse
allTagsResponseDecoder =
    map AllTagsResponse
        (field "allTags" (D.list tagDecoder))


homePageDataResponseDecoder : Decoder HomePageDataResponse
homePageDataResponseDecoder =
    map HomePageDataResponse
        (field "allTagsToShow" (D.list tagDecoder))


contentsResponseDecoder : Decoder ContentsResponse
contentsResponseDecoder =
    map2 ContentsResponse
        (field "totalPageCount" int)
        (field "contents" (D.list contentDecoder))


contentReadResponseDecoder : Decoder ContentReadResponse
contentReadResponseDecoder =
    map3 ContentReadResponse
        (field "idOfReadContentOrErrorMessage" string)
        (field "newTotalPageCountToSet" int)
        (field "contentToShowAsReplacementOnBottom" (maybe contentDecoder))


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
    map4 GotTag
        (field "tagId" string)
        (field "name" string)
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


bioResponseDecoder : Decoder BioResponse
bioResponseDecoder =
    map2 BioResponse
        (field "groups" (D.list bioGroupDecoder))
        (field "items" (D.list bioItemDecoder))


bioGroupDecoder : Decoder GotBioGroup
bioGroupDecoder =
    map6 GotBioGroup
        (field "url" string)
        (field "title" string)
        (field "displayIndex" int)
        (field "info" (maybe string))
        (field "bioGroupId" int)
        (field "bioItemOrder" (D.list int))


bioItemDecoder : Decoder GotBioItem
bioItemDecoder =
    map6 GotBioItem
        (field "bioItemID" int)
        (field "name" string)
        (field "groups" (D.list int))
        (field "groupNames" (D.list string))
        (field "colorHex" (maybe string))
        (field "info" (maybe string))


eksiKonserveResponseDecoder : Decoder EksiKonserveResponse
eksiKonserveResponseDecoder =
    map2 EksiKonserveResponse
        (field "topics" (D.list eksiKonserveTopicDecoder))
        (field "exceptions" (D.list eksiKonserveExceptionDecoder))


eksiKonserveTopicDecoder : Decoder EksiKonserveTopic
eksiKonserveTopicDecoder =
    map3 EksiKonserveTopic
        (field "name" string)
        (field "url" string)
        (field "count" int)


eksiKonserveExceptionDecoder : Decoder EksiKonserveException
eksiKonserveExceptionDecoder =
    map4 EksiKonserveException
        (field "message" string)
        (field "count" int)
        (field "timestamps" (D.list string))
        (D.succeed False)
