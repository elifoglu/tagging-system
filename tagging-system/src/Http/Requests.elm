module Requests exposing (createNewTag, getAllTagsResponse, getContent, getHomePageDataResponse, getSearchResult, getTagContents, getTimeZone, getUrlToRedirect, getWholeGraphData, postNewContent, previewContent, updateExistingContent, updateExistingTag)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Model, TotalPageCountRequestModel, UpdateContentPageData, UpdateTagPageModel, createContentPageModelEncoder, createTagPageModelEncoder, getContentRequestModelEncoder, getTagContentsRequestModelEncoder, updateContentPageDataEncoder, updateTagPageModelEncoder)
import App.Msg exposing (Msg(..), PreviewContentModel(..))
import DataResponse exposing (ContentID, allTagsResponseDecoder, contentDecoder, contentSearchResponseDecoder, contentsResponseDecoder, gotGraphDataDecoder, homePageDataResponseDecoder)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Tag.Model exposing (Tag)
import Task
import Time


apiURL =
    "http://localhost:8090/"


getTimeZone : Cmd Msg
getTimeZone =
    Task.perform GotTimeZone Time.here


getAllTagsResponse : Cmd Msg
getAllTagsResponse =
    Http.get
        { url = apiURL ++ "get-all-tags"
        , expect = Http.expectJson GotAllTagsResponse allTagsResponseDecoder
        }


getHomePageDataResponse : Cmd Msg
getHomePageDataResponse =
    Http.post
        { url = apiURL ++ "get-homepage-data"
        , body =
            Http.jsonBody
                (Encode.object
                    []
                )
        , expect = Http.expectJson GotHomePageDataResponse homePageDataResponseDecoder
        }


getTagContents : Tag -> Maybe Int -> Cmd Msg
getTagContents tag maybePage =
    let
        getTagContentsRequestModel : GetTagContentsRequestModel
        getTagContentsRequestModel =
            GetTagContentsRequestModel tag.tagId
                maybePage
    in
    Http.post
        { url = apiURL ++ "contents-of-tag"
        , body = Http.jsonBody (getTagContentsRequestModelEncoder getTagContentsRequestModel)
        , expect = Http.expectJson (GotContentsOfTag tag) contentsResponseDecoder
        }


getContent : Int -> Model -> Cmd Msg
getContent contentId model =
    Http.post
        { url = apiURL ++ "get-content"
        , body = Http.jsonBody (getContentRequestModelEncoder (GetContentRequestModel contentId))
        , expect = Http.expectJson GotContent contentDecoder
        }


getWholeGraphData : Cmd Msg
getWholeGraphData =
    Http.get
        { url = apiURL ++ "graph-data"
        , expect = Http.expectJson GotGraphData gotGraphDataDecoder
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


getSearchResult : String -> Model -> Cmd Msg
getSearchResult searchKeyword model =
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


getUrlToRedirect : String -> Cmd Msg
getUrlToRedirect path =
    Http.post
        { url = apiURL ++ "get-url-to-redirect"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "path", Encode.string path )
                    ]
                )
        , expect = Http.expectString GotUrlToRedirectResponse
        }