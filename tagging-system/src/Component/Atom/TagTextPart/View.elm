module TagTextPart.View exposing (viewTextPart)

import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import Html exposing (Html, a, br, div, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
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
            |> List.intersperse (br [] [])
        )


viewContentLine : Content -> Html Msg
viewContentLine content =
    div [ class "contentLineParent" ]
        [ div [ class "contentLineFirstChild" ]
            [ a [ href ("/contents/" ++ content.contentId) ]
                [ text (" • " ++ content.text)
                ]
            ]
        , div [ class "contentLineSecondChild" ]
            [ img
                [ class "contentEditAndDeleteIcons", onClick (ToggleUpdateContentModuleFor content), style "margin-left" "5px", src "/edit.png" ]
                []
            , img
                [ class "contentEditAndDeleteIcons", onClick (DeleteContent content), style "margin-left" "5px", src "/delete.png" ]
                []
            ]
        ]
