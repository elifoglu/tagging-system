module App.View exposing (view)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Browser exposing (Document)
import Content.View exposing (viewContentDiv)
import ContentSearch.View exposing (viewSearchContentDiv)
import CreateContent.View exposing (viewCreateContentDiv)
import CreateContentButton.View exposing (viewCreateContentButton)
import CreateTag.View exposing (viewCreateTagDiv)
import CreateTagButton.View exposing (viewCreateTagButton)
import HomeNavigator.View exposing (viewHomeNavigator)
import Html exposing (..)
import Html.Attributes exposing (..)
import NotFound.View exposing (view404Div)
import SearchBox.View exposing (viewSearchBoxDiv)
import Tag.View exposing (viewTagPageDiv)
import UpdateContent.View exposing (viewUpdateContentDiv)
import UpdateTag.View exposing (viewUpdateTagDiv)


view : Model -> Document Msg
view model =
    { title = "tagging system"
    , body =
        [ div []
            [ div [ class "header" ] [ viewHomeNavigator model, viewSearchBoxDiv model.activePage, viewCreateContentButton model, viewCreateTagButton model ]
            , div [ class "body" ]
                (case model.activePage of
                    TagPage status ->
                        case status of
                            Initialized initialized ->
                                [ viewTagPageDiv initialized model.allTags
                                , if initialized.createContentModule.isVisible then
                                    viewCreateContentDiv initialized.createContentModule.model

                                  else
                                    text ""
                                , if initialized.updateContentModule.isVisible then
                                    case initialized.updateContentModule.model of
                                        GotContentToUpdate updateContentPageData ->
                                            viewUpdateContentDiv updateContentPageData updateContentPageData.contentId

                                        NotInitializedYet _ ->
                                            text ""

                                        UpdateRequestIsSent _ ->
                                            text "..."

                                  else
                                    text ""
                                ]

                            _ ->
                                []

                    ContentPage status ->
                        case status of
                            NonInitialized _ ->
                                []

                            Initialized content ->
                                [ viewContentDiv Nothing content
                                , a [ href ("/update/content/" ++ String.fromInt content.contentId), class "updateContentLink" ] [ text "(update this content)" ]
                                ]

                    CreateTagPage status ->
                        case status of
                            NoRequestSentYet createTagPageModel ->
                                [ viewCreateTagDiv model createTagPageModel ]

                            RequestSent _ ->
                                [ text "..." ]

                    UpdateTagPage status ->
                        case status of
                            NoRequestSentYet ( updateTagPageModel, tagId ) ->
                                [ viewUpdateTagDiv updateTagPageModel tagId ]

                            RequestSent _ ->
                                [ text "..." ]

                    ContentSearchPage searchKeyword contents ->
                        [ viewSearchContentDiv searchKeyword contents ]

                    NotFoundPage ->
                        [ view404Div ]

                    MaintenancePage ->
                        [ text "*bakım çalışması*" ]
                )
            ]
        ]
    }
