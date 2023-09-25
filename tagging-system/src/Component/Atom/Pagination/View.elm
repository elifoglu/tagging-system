module Pagination.View exposing (viewPagination)

import App.Msg exposing (Msg)
import Html exposing (Html, a, button, div, text)
import Html.Attributes exposing (class, href, style)
import Pagination.Model exposing (Pagination)
import Tag.Model exposing (Tag)


viewPagination : Tag -> Pagination -> Html Msg
viewPagination tag pagination =
    if pagination.totalPageCount == 1 then
        div [ style "margin-top" "15px", style "margin-bottom" "15px", style "opacity" "0" ]
            [ text "0" ]

    else
        div [ style "margin-top" "30px", style "margin-bottom" "30px" ]
            (List.range 1 pagination.totalPageCount
                |> List.map (viewPageLinkForTagPage tag pagination.currentPage pagination.totalPageCount)
            )


viewPageLinkForTagPage : Tag -> Int -> Int -> Int -> Html Msg
viewPageLinkForTagPage tag currentPageNumber totalPageCount pageNumber =
    if currentPageNumber == pageNumber then
        if currentPageNumber == 1 || currentPageNumber == totalPageCount then
            text ""

        else
            button [ class "paginationButton currentPaginationButton" ]
                [ text "|"
                ]

    else
        a [ href ("/tags/" ++ tag.tagId ++ pageParamString pageNumber) ]
            [ button [ class "paginationButton" ]
                [ text <| String.fromInt pageNumber
                ]
            ]

pageParamString : Int -> String
pageParamString pageNumber =
    if pageNumber == 1 then
        ""

    else
        ("?page="
            ++ String.fromInt pageNumber)