module Requests exposing (createNewTag, getInitialData, getContent, getSearchResult, getTagContents, getTimeZone, postNewContent, previewContent, updateExistingContent, updateExistingTag)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Model, UpdateContentPageData, UpdateTagPageModel, createContentPageModelEncoder, createTagPageModelEncoder, getContentRequestModelEncoder, getTagContentsRequestModelEncoder, updateContentPageDataEncoder, updateTagPageModelEncoder)
import App.Msg exposing (Msg(..), PreviewContentModel(..))
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
        , body = Http.jsonBody (getTagContentsRequestModelEncoder getTagContentsRequestModel)
        , expect = Http.expectJson (GotDataOfTag tag) tagDataResponseDecoder
        }


getContent : Int -> Cmd Msg
getContent contentId =
    Http.post
        { url = apiURL ++ "get-content"
        , body = Http.jsonBody (getContentRequestModelEncoder (GetContentRequestModel contentId))
        , expect = Http.expectJson GotContent contentDecoder
        }


postNewContent : CreateContentPageModel -> Cmd Msg
postNewContent model =
    Http.post
        { url = apiURL ++ "contents"
        , body = Http.jsonBody (createContentPageModelEncoder model)
        , expect = Http.expectJson GotContent contentDecoder
        }


updateExistingContent : ContentID -> UpdateContentPageData -> Cmd Msg
updateExistingContent contentId model =
    Http.post
        { url = apiURL ++ "contents/" ++ String.fromInt contentId
        , body = Http.jsonBody (updateContentPageDataEncoder contentId model)
        , expect = Http.expectJson GotContent contentDecoder
        }


previewContent : PreviewContentModel -> Cmd Msg
previewContent model =
    case model of
        PreviewForContentCreate createContentPageModel ->
            Http.post
                { url = apiURL ++ "preview-content"
                , body = Http.jsonBody (createContentPageModelEncoder createContentPageModel)
                , expect = Http.expectJson (GotContentToPreviewForCreatePage createContentPageModel) contentDecoder
                }

        PreviewForContentUpdate contentID updateContentPageData ->
            Http.post
                { url = apiURL ++ "preview-content"
                , body = Http.jsonBody (updateContentPageDataEncoder contentID updateContentPageData)
                , expect = Http.expectJson (GotContentToPreviewForUpdatePage contentID updateContentPageData) contentDecoder
                }


createNewTag : CreateTagPageModel -> Cmd Msg
createNewTag model =
    Http.post
        { url = apiURL ++ "tags"
        , body = Http.jsonBody (createTagPageModelEncoder model)
        , expect = Http.expectString GotTagUpdateOrCreationDoneResponse
        }


updateExistingTag : String -> UpdateTagPageModel -> Cmd Msg
updateExistingTag tagId model =
    Http.post
        { url = apiURL ++ "tags/" ++ tagId
        , body = Http.jsonBody (updateTagPageModelEncoder model)
        , expect = Http.expectString GotTagUpdateOrCreationDoneResponse
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
