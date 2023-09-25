module Home.View exposing (..)

import App.Model exposing (IconInfo, Model, Page(..))
import App.Msg exposing (Msg(..))
import Html exposing (Html, a, br, div, img, input, span, text)
import Html.Attributes exposing (class, href, placeholder, src, style, type_, value)
import Html.Events exposing (onInput)
import Tag.Model exposing (Tag)
import TagInfoIcon.View exposing (viewTagInfoIcon)


viewHomePageDiv : Maybe (List Tag) -> Html Msg
viewHomePageDiv allTagsToShow =
    div [ class "homepage homepageTagsFont", style "width" "auto", style "float" "left" ]
        ((tagsToShow allTagsToShow
            |> List.map viewTag
            |> List.intersperse (br [] [])
         )
            ++ [ br [] [] ]
            ++ viewSearchBoxDiv
        )


tagsToShow : Maybe (List Tag) -> List Tag
tagsToShow allTagsToShow =
    Maybe.withDefault [] allTagsToShow



tagCountCurrentlyShownOnPage : Maybe (List Tag) -> Int
tagCountCurrentlyShownOnPage allTags =
    let
        tagsCount =
            List.length (tagsToShow allTags)
    in
    if tagsCount == 0 then
        1

    else
        tagsCount


viewTag : Tag -> Html Msg
viewTag tag =
    span []
        [ a
            [ class "homepageTagA"
            , href
                ("/tags/"
                    ++ tag.tagId
                )
            ]
            [ text tag.name ]
        , text " "
        , viewTagInfoIcon tag
        ]



viewSearchBoxDiv : List (Html Msg)
viewSearchBoxDiv =
    [ div [ style "margin-top" "5px", style "margin-bottom" "10px", style "margin-left" "-5px" ]
            [ input [ type_ "text", class "contentSearchInput", placeholder "ara...", value "", onInput GotSearchInput, style "margin-left" "5px" ] [] ]
        ]

