module TagInfoIcon.View exposing (viewTagInfoIcon)

import App.Msg exposing (Msg)
import Html exposing (Html, a, img, text)
import Html.Attributes exposing (class, href, src, style)
import Tag.Model exposing (Tag)


viewTagInfoIcon : Tag -> Html Msg
viewTagInfoIcon tag =
    case tag.infoContentId of
        Just contentId ->
            a
                [ href ("/contents/" ++ String.fromInt contentId)
                ]
                [ img [ class "navToTagDesc", src "/info.svg" ] []
                ]

        Nothing ->
            text ""
