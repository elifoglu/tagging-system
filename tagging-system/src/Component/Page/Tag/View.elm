module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel)
import App.Msg exposing (Msg(..))
import Html exposing (Html, a, b, br, div, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
import Tag.TagTextUtil exposing (viewTagText)
import TagInfoIcon.View exposing (viewTagInfoIcon)


viewTagPageDiv : InitializedTagPageModel -> List Tag -> Html Msg
viewTagPageDiv initialized allTags =
    div [ style "margin-top" "27px"]
        [ viewLeftFrame initialized allTags
        , viewRightFrame initialized
        ]


viewLeftFrame : InitializedTagPageModel -> List Tag -> Html Msg
viewLeftFrame initialized allTags =
    div [ class "leftFrameOnTagPage leftFrameTagsFont" ]
        [ div [ style "margin-left" "20px", style "font-size" "14px" ] [ b [] [ text ("#" ++ initialized.tag.name) ] ]
        , viewTagsDiv initialized.tag.parentTags allTags "/up.png"
        , viewTagsDiv initialized.tag.childTags allTags "/down.png"
        ]


viewTagsDiv : List String -> List Tag -> String -> Html Msg
viewTagsDiv tagIds allTags iconSrc =
    if List.length tagIds == 0 then
        text " "

    else
        div [ class "tagsDiv" ]
            [ div [ class "tagsDivChild tagsDivFirstChild" ] [ img [ class "upAndDownIcons", src iconSrc ] [] ]
            , div [ class "tagsDivChild" ]
                (tagIds
                    |> List.map (tagByIdForced allTags)
                    |> List.map viewTag
                    |> List.intersperse (br [] [])
                )
            ]


viewRightFrame : InitializedTagPageModel -> Html Msg
viewRightFrame initialized =
    div [ class "rightFrameOnTagPage" ]
        [ viewTagText initialized.tag initialized.textParts
        ]

viewTag : Tag -> Html Msg
viewTag tag =
    span []
        [ a
            [ class "tagPageTagA"
            , href
                ("/tags/"
                    ++ tag.tagId
                )
            ]
            [ text tag.name ]
        , text " "
        , viewTagInfoIcon tag
        ]
