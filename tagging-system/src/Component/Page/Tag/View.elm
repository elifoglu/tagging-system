module Tag.View exposing (..)

import App.Model exposing (InitializedTagPageModel)
import App.Msg exposing (Msg(..))
import Contents.View exposing (viewContentDivs)
import Home.View exposing (viewTag)
import Html exposing (Html, br, div, text)
import Html.Attributes exposing (class, style)
import Pagination.View exposing (viewPagination)
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)


viewTagPageDiv : InitializedTagPageModel -> List Tag -> Html Msg
viewTagPageDiv initialized allTags =
    div []
        ([ div
            [ class "homepage homepageTagsFont"
            , style "width" "auto"
            ]
            [ viewParentTagsDiv initialized.tag allTags
            , viewChildTagsDiv initialized.tag allTags
            ]
         ]
            ++ (viewContentDivs initialized.contents
                    ++ [ viewPagination initialized.tag initialized.pagination
                       ]
               )
        )


viewParentTagsDiv : Tag -> List Tag -> Html Msg
viewParentTagsDiv tag allTags =
    viewTagsDiv (tag.parentTags |> List.map (tagByIdForced allTags))


viewChildTagsDiv : Tag -> List Tag -> Html Msg
viewChildTagsDiv tag allTags =
    viewTagsDiv (tag.childTags |> List.map (tagByIdForced allTags))


viewTagsDiv : List Tag -> Html Msg
viewTagsDiv tags =
    div [ style "margin-top" "20px" ]
        (tags
            |> List.map viewTag
            |> List.intersperse (br [] [])
        )
