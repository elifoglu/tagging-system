module ContentSearch.View exposing (..)

import App.Msg exposing (KeyDownPlace(..), Msg(..))
import Content.Model exposing (Content)
import Content.View exposing (viewContentDivOnSearchPage)
import Html exposing (Html, div, hr, input, span, text)
import Html.Attributes exposing (class, id, placeholder, style, type_, value)
import Html.Events exposing (onInput)
import Component.KeydownHandler exposing (onKeyDown)


viewSearchContentDiv : String -> List Content -> Html Msg
viewSearchContentDiv searchKeyword contents =
    div [ class "contentSearchPageDiv"]
        [ input [ type_ "text", id "contentSearchInputInSearchPage", class "contentSearchInput", placeholder "write sth to search", value searchKeyword, onKeyDown (KeyDown SearchInputOnSearchPage), onInput GotSearchInput, style "width" "130px" ] []
        , span [ class "searchContentInfoText" ]
            [ text
                (if List.length contents > 0 then
                    String.fromInt (List.length contents) ++ " items found"

                 else if String.length searchKeyword >= 2 && List.isEmpty contents then
                    "search better!"

                 else
                    "please enter at least 3 chars"
                )
            ]
        , div [ class "contentSeparatorOnSearchPage" ]
            (contents
                |> List.map (viewContentDivOnSearchPage (Just searchKeyword))
                |> List.intersperse (hr [] [])
            )
        ]
