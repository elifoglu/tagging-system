module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel)
import App.Msg exposing (Msg(..))
import Contents.View exposing (viewContentDivs)
import Html exposing (Html, a, b, br, div, img, input, span, text)
import Html.Attributes exposing (class, href, placeholder, src, style, type_, value)
import Html.Events exposing (onInput)
import Pagination.View exposing (viewPagination)
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
import TagInfoIcon.View exposing (viewTagInfoIcon)


viewTagPageDiv : InitializedTagPageModel -> List Tag -> Html Msg
viewTagPageDiv initialized allTags =
    div []
        [ viewLeftFrame initialized allTags
        , viewRightFrame initialized
        ]


viewLeftFrame : InitializedTagPageModel -> List Tag -> Html Msg
viewLeftFrame initialized allTags =
    div [ class "leftFrameOnTagPage leftFrameTagsFont" ]
        [ viewTagsDiv initialized.tag.parentTags allTags "/up.png"
        , viewTagsDiv initialized.tag.childTags allTags "/down.png"
        , viewSearchBoxDiv
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
        [ viewContentDivs initialized.contents
        , viewPagination initialized.tag initialized.pagination
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


viewSearchBoxDiv : Html Msg
viewSearchBoxDiv =
    div [ style "margin-top" "20px", style "margin-left" "25px" ]
        [ input [ type_ "text", class "contentSearchInput", placeholder "search...", value "", onInput GotSearchInput ] [] ]
