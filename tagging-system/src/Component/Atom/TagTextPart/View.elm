module TagTextPart.View exposing (viewTextPart)

import App.Msg exposing (Msg)
import Content.Model exposing (Content)
import Html exposing (Html, a, div, span, text)
import Html.Attributes exposing (class, href)
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)


viewTextPart : Tag -> TagTextPart -> Html Msg
viewTextPart baseTag tagTextPart =
    div []
        [ viewTagAsATitle baseTag tagTextPart
        , viewContentsLineByLine tagTextPart.contents
        ]


viewTagAsATitle : Tag -> TagTextPart -> Html Msg
viewTagAsATitle baseTag tagTextPart =
    if tagTextPart.tag.tagId /= baseTag.tagId then
        span [ class "tagAsATitle" ] [ a [ href ("/tags/" ++ tagTextPart.tag.tagId) ] [ text ("#" ++ tagTextPart.tag.name) ] ]

    else
        text ""


viewContentsLineByLine : List Content -> Html Msg
viewContentsLineByLine contents =
    div []
        (contents
            |> List.map viewContentLine
        )


viewContentLine : Content -> Html Msg
viewContentLine content =
    div []
        [ span [] [ a [ href ("/contents/" ++ content.contentId) ] [ text (" • " ++ content.text) ] ]
        ]
