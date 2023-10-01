module App.View exposing (view)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Browser exposing (Document)
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
            [ div [ class "header" ] [ viewHomeNavigator model, viewSearchBoxDiv model.activePage, viewUndoDiv]
            , div [ class "body" ]
                (case model.activePage of
                    TagPage status ->
                        case status of
                            Initialized initialized ->
                                [ viewTagPageDiv model.homeTagId initialized model.allTags ]

                            _ ->
                                []

                    ContentSearchPage searchKeyword contents ->
                        [ viewSearchContentDiv searchKeyword contents ]

                    NotFoundPage ->
                        [ view404Div ]
                )
            ]
        ]
    }


viewUndoDiv : Html Msg
viewUndoDiv =
    div [ class "undoDivInHeader" ]
        [ img [ class "undoIcon", onClick Undo, style "margin-left" "5px", src "/undo.png" ]
            []
        ]
