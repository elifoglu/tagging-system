module Tag.View exposing (viewTagPageDiv)

import App.Model exposing (ContentModuleVisibility(..), InitializedTagPageModel, Model, TagModuleVisibility(..), Theme, UpdateContentModuleModel)
import App.Msg exposing (Msg(..))
import App.ThemeSelector exposing (viewThemeSelectorBoxDiv)
import CreateContent.View exposing (viewCreateContentDiv)
import CreateTag.View exposing (viewCreateTagDiv)
import Html exposing (Html, a, b, br, div, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Tag.Model exposing (Tag)
import Tag.TagTextTypeSelectionBox exposing (viewTagTextTypeSelectionBoxDiv)
import Tag.TagTextUtil exposing (viewTagText)
import Tag.Util exposing (tagByIdForced)
import UpdateContent.View exposing (viewUpdateContentDiv)
import UpdateTag.View exposing (viewUpdateTagDiv)


viewTagPageDiv : Model -> InitializedTagPageModel -> Html Msg
viewTagPageDiv model initialized =
    div [ style "margin-top" "25px" ]
        [ viewLeftFrame model.homeTagId initialized model.allTags model.activeTheme
        , viewMidFrame model initialized
        , viewRightFrame initialized
        ]


viewRightFrame : InitializedTagPageModel -> Html Msg
viewRightFrame initialized =
    div [ class "rightFrameOnTagPage" ]
        [ case initialized.oneOfContentModuleIsVisible of
            CreateContentModuleIsVisible ->
                viewCreateContentDiv initialized.createContentModule

            UpdateContentModuleIsVisible ->
                viewUpdateContentDiv initialized.updateContentModule
        ]


viewLeftFrame : String -> InitializedTagPageModel -> List Tag -> Theme -> Html Msg
viewLeftFrame homeTagId initialized allTags activeTheme =
    div [ class "leftFrameOnTagPage" ]
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
            [ b [] [ text ("# " ++ initialized.tag.name) ]
            , img [ class "tagEditIcon", onClick ToggleUpdateTagModuleVisibility, src "/edit.png" ] []
            ]
        , viewTagsDiv initialized.tag.childTags allTags Child
        , viewTagTextTypeSelectionBoxDiv initialized.activeTagTextViewType
        , case initialized.oneOfTagModuleIsVisible of
            CreateTagModuleIsVisible ->
                viewCreateTagDiv initialized.createTagModule

            UpdateTagModuleIsVisible ->
                viewUpdateTagDiv homeTagId initialized.updateTagModule
        , viewThemeSelectorBoxDiv activeTheme
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


viewMidFrame : Model -> InitializedTagPageModel -> Html Msg
viewMidFrame model initialized =
    div [ class "midFrameOnTagPage" ]
        [ viewTagText model
            initialized.tag
            initialized.textPartsForGroupView
            initialized.textPartsForLineView
            initialized.textPartsForDistinctGroupView
            initialized.activeTagTextViewType
            initialized.quickContentEditModule
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
            [ b [] [ text "# " ], text tag.name ]
        , text " "
        ]
