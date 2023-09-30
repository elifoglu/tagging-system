module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel, TagModuleVisibility(..))
import App.Msg exposing (Msg(..))
import CreateTag.View exposing (viewCreateTagDiv)
import Html exposing (Html, a, b, br, div, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Tag.Model exposing (Tag)
import Tag.TagTextUtil exposing (viewTagText)
import Tag.Util exposing (tagByIdForced)
import UpdateTag.View exposing (viewUpdateTagDiv)


viewTagPageDiv : InitializedTagPageModel -> List Tag -> Html Msg
viewTagPageDiv initialized allTags =
    div [ style "margin-top" "27px" ]
        [ viewLeftFrame initialized allTags
        , viewRightFrame initialized
        ]


viewLeftFrame : InitializedTagPageModel -> List Tag -> Html Msg
viewLeftFrame initialized allTags =
    div [ class "leftFrameOnTagPage leftFrameTagsFont" ]
        [ viewTagsDiv initialized.tag.parentTags allTags Parent
        , div
            [ style "font-size" "14px"
            , style "padding-left"
                (if not (List.isEmpty initialized.tag.parentTags) then
                    "5px"

                 else
                    "0px"
                )
            ]
            [ b [] [ text ("#" ++ initialized.tag.name) ]
            , img [ class "tagEditIcon", onClick ToggleUpdateTagModuleVisibility, style "margin-left" "5px", src "/edit.png" ] []

            ]
        , viewTagsDiv initialized.tag.childTags allTags Child
        , case initialized.oneOfIsVisible of
                CreateTagModuleIsVisible ->
                    viewCreateTagDiv initialized.createTagModuleModel
                UpdateTagModuleIsVisible ->
                    viewUpdateTagDiv initialized.updateTagModuleModel
        ]


type TagType
    = Parent
    | Child


viewTagsDiv : List String -> List Tag -> TagType -> Html Msg
viewTagsDiv tagIds allTags tagType =
    div []
        (tagIds
            |> List.map (tagByIdForced allTags)
            |> List.map (viewTag tagType)
            |> List.intersperse (br [] [])
        )


viewRightFrame : InitializedTagPageModel -> Html Msg
viewRightFrame initialized =
    div [ class "rightFrameOnTagPage" ]
        [ viewTagText initialized.tag initialized.textParts
        ]


viewTag : TagType -> Tag -> Html Msg
viewTag tagType tag =
    span []
        [ a
            [ class "tagPageTagA"
            , style "padding-left"
                (case tagType of
                    Parent ->
                        "0px"

                    Child ->
                        "10px"
                )
            , href
                ("/tags/"
                    ++ tag.tagId
                )
            ]
            [ text tag.name ]
        , text " "
        ]
