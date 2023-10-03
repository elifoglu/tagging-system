module Requests exposing (createContent, createContentViaCSAAdder, createTag, deleteContent, deleteTag, dragContent, getInitialData, getSearchResult, getTagContents, getTimeZone, undo, updateContent, updateTag, updateContentViaQuickContentEditBox)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, DragContentRequestModel, GetTagContentsRequestModel, IconInfo, LocatedAt, Model, TagTextViewType(..), UpdateContentModuleModel, UpdateTagModuleModel, createContentRequestEncoder, createTagRequestEncoder, deleteTagRequestEncoder, dragContentRequestEncoder, getDataOfTagRequestModelEncoder, requestEncoderForContentUpdateViaQuickContentEditBox, updateContentRequestEncoder, updateTagRequestEncoder)
import App.Msg exposing (CrudAction(..), Msg(..))
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, contentSearchResponseDecoder, initialDataResponseDecoder, tagTextResponseDecoder)
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
        { url = apiURL ++ "tag-text"
        , body = Http.jsonBody (getDataOfTagRequestModelEncoder getTagContentsRequestModel)
        , expect = Http.expectJson (GotTagTextOfTag tag) tagTextResponseDecoder
        }


createContent : CreateContentModuleModel -> Cmd Msg
createContent model =
    Http.post
        { url = apiURL ++ "contents"
        , body = Http.jsonBody (createContentRequestEncoder model)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse CreateContentAct)
        }


createContentViaCSAAdder : String -> String -> String -> TagTextViewType -> String -> String -> Cmd Msg
createContentViaCSAAdder text tagIdOfTagTextPart tagIdOfActiveTagPage activeTagTextViewType existingContentToAddFrontOrBackOfIt frontOrBack =
    Http.post
        { url = apiURL ++ "contents"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "title", Encode.string "" )
                    , ( "text", Encode.string text )
                    , ( "tags"
                      , Encode.list Encode.string
                            [ case activeTagTextViewType of
                                GroupView ->
                                    tagIdOfTagTextPart

                                DistinctGroupView ->
                                    tagIdOfTagTextPart

                                LineView ->
                                    tagIdOfActiveTagPage
                            ]
                      )
                    , ( "existingContentContentIdToAddFrontOrBackOfIt", Encode.string existingContentToAddFrontOrBackOfIt )
                    , ( "existingContentTagIdToAddFrontOrBackOfIt", Encode.string tagIdOfTagTextPart )
                    , ( "frontOrBack", Encode.string frontOrBack )
                    ]
                )
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse CreateContentActViaCSAAdder)
        }


updateContent : UpdateContentModuleModel -> Cmd Msg
updateContent model =
    Http.post
        { url = apiURL ++ "contents/" ++ model.content.contentId
        , body = Http.jsonBody (updateContentRequestEncoder model)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse UpdateContentAct)
        }

updateContentViaQuickContentEditBox : Content -> String -> Cmd Msg
updateContentViaQuickContentEditBox content updatedText =
    Http.post
        { url = apiURL ++ "contents/" ++ content.contentId
        , body = Http.jsonBody (requestEncoderForContentUpdateViaQuickContentEditBox content updatedText)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse UpdateContentAct)
        }


deleteContent : String -> Cmd Msg
deleteContent contentId =
    Http.post
        { url = apiURL ++ "delete-content/" ++ contentId
        , body = Http.emptyBody
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse DeleteContentAct)
        }


createTag : CreateTagModuleModel -> Cmd Msg
createTag model =
    Http.post
        { url = apiURL ++ "tags"
        , body = Http.jsonBody (createTagRequestEncoder model)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse CreateTagAct)
        }


updateTag : UpdateTagModuleModel -> Cmd Msg
updateTag model =
    Http.post
        { url = apiURL ++ "tags/" ++ model.tagId
        , body = Http.jsonBody (updateTagRequestEncoder model)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse UpdateTagAct)
        }


deleteTag : UpdateTagModuleModel -> Cmd Msg
deleteTag model =
    Http.post
        { url = apiURL ++ "delete-tag/" ++ model.tagId
        , body = Http.jsonBody (deleteTagRequestEncoder model)
        , expect = Http.expectString (GotTagOrContentCreateUpdateDeleteDoneResponse DeleteTagAct)
        }


dragContent : DragContentRequestModel -> Cmd Msg
dragContent model =
    Http.post
        { url = apiURL ++ "drag-content"
        , body = Http.jsonBody (dragContentRequestEncoder model)
        , expect = Http.expectString DragDoneResponse
        }


undo : Cmd Msg
undo =
    Http.get
        { url = apiURL ++ "undo"
        , expect = Http.expectString UndoDoneResponse
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
