module App.View exposing (view)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Browser exposing (Document)
import ContentPage.View exposing (viewContentPageDiv)
import ContentSearch.View exposing (viewSearchContentDiv)
import HomeNavigator.View exposing (viewHomeNavigator)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import NotFound.View exposing (view404Div)
import SearchBox.View exposing (viewSearchBoxDiv)
import Tag.View exposing (viewTagPageDiv)


view : Model -> Document Msg
view model =
    { title = "tagging system"
    , body =
        [ div []
            [ div [ class "header" ] [ viewHomeNavigator model, viewSearchBoxDiv model.activePage, viewUndoDiv model ]
            , div [ class "body" ]
                (case model.activePage of
                    TagPage status ->
                        case status of
                            Initialized initialized ->
                                [ viewTagPageDiv model initialized ]

                            _ ->
                                []

                    ContentPage status ->
                        case status of
                            Initialized initialized ->
                                [ viewContentPageDiv initialized ]

                            _ ->
                                []

                    ContentSearchPage searchKeyword contents _ ->
                        [ viewSearchContentDiv searchKeyword contents ]

                    NotFoundPage ->
                        [ view404Div ]
                )
            ]
        ]
    }


viewUndoDiv : Model -> Html Msg
viewUndoDiv model =
    if not model.undoable then
        text ""

    else
        case model.activePage of
            TagPage _ ->
                div [ class "undoDivInHeader" ]
                    [ img [ class "undoIcon", onClick Undo, style "margin-left" "5px", src "/undo.svg" ]
                        []
                    , img [ class "undoIcon", onClick ClearUndoStack, style "margin-left" "5px", src "/clear-undo-stack.png" ]
                        []
                    ]

            ContentPage _ ->
                div [ class "undoDivInHeader" ]
                    [ img [ class "undoIcon", onClick Undo, style "margin-left" "5px", src "/undo.svg" ]
                        []
                    , img [ class "undoIcon", onClick ClearUndoStack, style "margin-left" "5px", src "/clear-undo-stack.png" ]
                        []
                    ]

            _ ->
                text ""
