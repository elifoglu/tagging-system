module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel)
import App.Msg exposing (Msg(..))
import Contents.View exposing (viewContentDivs)
import Html exposing (Html, a, b, br, div, input, span, text)
import Html.Attributes exposing (class, href, placeholder, style, type_, value)
import Html.Events exposing (onInput)
import Pagination.View exposing (viewPagination)
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
import TagInfoIcon.View exposing (viewTagInfoIcon)


viewTagPageDiv : InitializedTagPageModel -> List Tag -> Html Msg
viewTagPageDiv initialized allTags =
    div [ class "parentFrameOnTagPage" ]
        [ viewLeftFrame initialized allTags
        , viewRightFrame initialized allTags
        ]


viewLeftFrame : InitializedTagPageModel -> List Tag -> Html Msg
viewLeftFrame initialized allTags =
    div [ class "leftFrameOnTagPage"]
        [ div
            [ class "tagPageTagsFont"
            , style "width" "auto"
            ]
            [ viewParentTagsDiv initialized.tag allTags
            , viewChildTagsDiv initialized.tag allTags
            , viewSearchBoxDiv
            ]
        ]


viewRightFrame : InitializedTagPageModel -> List Tag -> Html Msg
viewRightFrame initialized allTags =
    div [ class "rightFrameOnTagPage" ]
        (viewContentDivs initialized.contents
            ++ [ viewPagination initialized.tag initialized.pagination
               ]
        )


viewParentTagsDiv : Tag -> List Tag -> Html Msg
viewParentTagsDiv tag allTags =
    viewTagsDiv "parent tags" (tag.parentTags |> List.map (tagByIdForced allTags))


viewChildTagsDiv : Tag -> List Tag -> Html Msg
viewChildTagsDiv tag allTags =
    viewTagsDiv "child tags" (tag.childTags |> List.map (tagByIdForced allTags))


viewTagsDiv : String -> List Tag -> Html Msg
viewTagsDiv tagListHeader tags =
    if List.length tags > 0 then
        div [ style "margin-top" "20px" ]
            (b [ style "font-weight" "bolder" ] [ text tagListHeader ]
                :: (br [] []
                        :: (tags
                                |> List.map viewTag
                                |> List.intersperse (br [] [])
                           )
                   )
            )

    else
        text ""


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
    div [ style "margin-top" "5px", style "margin-bottom" "10px", style "margin-left" "-5px" ]
        [ input [ type_ "text", class "contentSearchInput", placeholder "search...", value "", onInput GotSearchInput, style "margin-left" "5px" ] [] ]
