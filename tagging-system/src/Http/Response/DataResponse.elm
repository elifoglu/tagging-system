module DataResponse exposing (ContentID, ContentSearchResponse, GotContent, GotContentDate, GotTag, GotTagTextPart, InitialDataResponse, TagTextResponse, contentDecoder, contentSearchResponseDecoder, initialDataResponseDecoder, tagTextResponseDecoder, TagID)

import Json.Decode as D exposing (Decoder, bool, field, int, map, map2, map3, map6, map7, map8, maybe, string)


type alias InitialDataResponse =
    { allTags : List GotTag, homeTagId : String, undoable: Bool }


type alias TagTextResponse =
    { textPartsForGroupView : List GotTagTextPart
    , textPartsForLineView : List GotTagTextPart
    , textPartsForDistinctGroupView : List GotTagTextPart
    }


type alias GotTagTextPart =
    { tag : GotTag
    , contents : List GotContent
    }


type alias GotTag =
    { tagId : String
    , name : String
    , parentTags : List String
    , childTags : List String
    , contentCount : Int
    , description : String
    }


type alias GotContent =
    { title : Maybe String, createdAt : GotContentDate, lastModifiedAt : GotContentDate, isDeleted: Bool, contentId : String, content : String, tagIds : List String, tagIdOfCurrentTextPart: Maybe String }


type alias ContentID =
    String


type alias TagID =
    String


type alias GotContentDate =
    String


type alias ContentSearchResponse =
    { contents : List GotContent
    }


initialDataResponseDecoder : Decoder InitialDataResponse
initialDataResponseDecoder =
    map3 InitialDataResponse
        (field "allTags" (D.list tagDecoder))
        (field "homeTagId" string)
        (field "undoable" bool)


tagTextResponseDecoder : Decoder TagTextResponse
tagTextResponseDecoder =
    map3 TagTextResponse
        (field "textPartsForGroupView" (D.list tagTextPartDecoder))
        (field "textPartsForLineView" (D.list tagTextPartDecoder))
        (field "textPartsForDistinctGroupView" (D.list tagTextPartDecoder))


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
        (field "description" string)


contentDecoder : Decoder GotContent
contentDecoder =
    map8 GotContent
        (maybe (field "title" string))
        (field "createdAt" dateDecoder)
        (field "lastModifiedAt" dateDecoder)
        (field "isDeleted" bool)
        (field "contentId" string)
        (field "content" string)
        (field "tagIds" (D.list string))
        (field "tagIdOfCurrentTextPart" (D.maybe string))


tagTextPartDecoder : Decoder GotTagTextPart
tagTextPartDecoder =
    map2 GotTagTextPart
        (field "tag" tagDecoder)
        (field "contents" (D.list contentDecoder))


dateDecoder : Decoder GotContentDate
dateDecoder =
    D.string
