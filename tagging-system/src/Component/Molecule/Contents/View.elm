module Contents.View exposing (viewContentDivs)

import App.Msg exposing (Msg)
import Content.Model exposing (Content)
import Content.View exposing (viewContentDiv)
import Html exposing (Html, div, hr)
import Html.Attributes exposing (style)


viewContentDivs : List Content -> List (Html Msg)
viewContentDivs contents =
    [ div [ style "margin-top" "20px" ]
        (contents
            |> List.map (viewContentDiv Nothing)
            |> List.intersperse (hr [] [])
        )
    ]
