module Requests exposing (createTag, getInitialData, getContent, getSearchResult, getTagContents, getTimeZone, createContent, updateContent, updateTag)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Model, UpdateContentModuleModel, UpdateTagModuleModel, createContentRequestEncoder, createTagRequestEncoder, getContentRequestModelEncoder, getDataOfTagRequestModelEncoder, updateContentRequestEncoder, updateTagPageModelEncoder)
import App.Msg exposing (Msg(..))
import DataResponse exposing (ContentID, initialDataResponseDecoder, contentDecoder, contentSearchResponseDecoder, tagDataResponseDecoder)
import Http
import Json.Encode as Encode
import Tag.Model exposing (Tag)
import Task
import Time


apiURL =
    "http://localhost:8090/"


getTimeZone : Cmd Msg
getTimeZone =
    Task.perform GotTimeZone Time.here


getInitialData : Cmd Msg
getInitialData =
    Http.get
        { url = apiURL ++ "get-initial-data"
        , expect = Http.expectJson GotInitialDataResponse initialDataResponseDecoder
        }


getTagContents : Tag -> Cmd Msg
getTagContents tag =
    let
        getTagContentsRequestModel : GetTagContentsRequestModel
        getTagContentsRequestModel =
            GetTagContentsRequestModel tag.tagId
    in
    Http.post
        { url = apiURL ++ "contents-of-tag"
        , body = Http.jsonBody (getDataOfTagRequestModelEncoder getTagContentsRequestModel)
        , expect = Http.expectJson (GotDataOfTag tag) tagDataResponseDecoder
        }


getContent : String -> Cmd Msg
getContent contentId =
    Http.post
        { url = apiURL ++ "get-content"
        , body = Http.jsonBody (getContentRequestModelEncoder (GetContentRequestModel contentId))
        , expect = Http.expectJson GotContent contentDecoder
        }


createContent : CreateContentModuleModel -> Cmd Msg
createContent model =
    Http.post
        { url = apiURL ++ "contents"
        , body = Http.jsonBody (createContentRequestEncoder model)
        , expect = Http.expectString GotTagOrContentCreateUpdateDeleteDoneResponse
        }


updateContent : UpdateContentModuleModel -> Cmd Msg
updateContent model =
    Http.post
        { url = apiURL ++ "contents/" ++ model.contentId
        , body = Http.jsonBody (updateContentRequestEncoder model)
        , expect = Http.expectString GotTagOrContentCreateUpdateDeleteDoneResponse
        }


createTag : CreateTagModuleModel -> Cmd Msg
createTag model =
    Http.post
        { url = apiURL ++ "tags"
        , body = Http.jsonBody (createTagRequestEncoder model)
        , expect = Http.expectString GotTagOrContentCreateUpdateDeleteDoneResponse
        }


updateTag : UpdateTagModuleModel -> Cmd Msg
updateTag model =
    Http.post
        { url = apiURL ++ "tags/" ++ model.tagId
        , body = Http.jsonBody (updateTagPageModelEncoder model)
        , expect = Http.expectString GotTagOrContentCreateUpdateDeleteDoneResponse
        }


getSearchResult : String -> Cmd Msg
getSearchResult searchKeyword =
    Http.post
        { url = apiURL ++ "search"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "keyword", Encode.string searchKeyword )
                    ]
                )
        , expect = Http.expectJson GotContentSearchResponse contentSearchResponseDecoder
        }
