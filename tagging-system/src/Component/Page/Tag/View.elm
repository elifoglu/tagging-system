module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import Content.View exposing (viewContentDiv)
import Html exposing (Html, a, b, br, div, hr, img, input, span, text)
import Html.Attributes exposing (class, href, placeholder, src, style, type_, value)
import Html.Events exposing (onInput)
import Markdown exposing (defaultOptions)
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
        [ div [ style "margin-top" "20px", style "margin-left" "20px", style "font-size" "14px" ] [ b [] [ text ("#" ++ initialized.tag.name) ] ]
        , viewTagsDiv initialized.tag.parentTags allTags "/up.png"
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
        [ viewContentsDiv initialized.contents
        , viewPagination initialized.tag initialized.pagination
        ]


viewContentsDiv : List Content -> Html Msg
viewContentsDiv contents =
    if "condensedView" == "condensedView" then
        div []
            [ Markdown.toHtmlWith { defaultOptions | sanitize = False }
                [ class "markdownDiv contentFont" ]
                (let
                    contentTexts : List String
                    contentTexts =
                        contents
                            |> List.map (\c -> " [•](/contents/" ++ String.fromInt c.contentId ++ ") " ++ c.text)
                            |> List.intersperse "  \n\n"
                 in
                 String.concat contentTexts
                )
            ]

    else
        div []
            (contents
                |> List.map (viewContentDiv Nothing)
                |> List.intersperse (hr [] [])
            )


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
