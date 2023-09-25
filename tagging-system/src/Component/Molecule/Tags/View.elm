module Tags.View exposing (viewParentTagsDiv, viewChildTagsDiv)

import App.Msg exposing (Msg)
import Html exposing (Html, a, br, div, hr, text)
import Html.Attributes exposing (href, style)
import Tag.Model exposing (Tag)

viewParentTagsDiv: Tag -> Html Msg
viewParentTagsDiv tag =
    viewTagsDiv tag.parentTags

viewChildTagsDiv: Tag -> Html Msg
viewChildTagsDiv tag =
    viewTagsDiv tag.childTags

type alias TagId = String

viewTagsDiv : List TagId -> Html Msg
viewTagsDiv tagIds =
    div [ style "margin-top" "20px" ]
          ( tagIds
            |> List.map tagToText
            |> List.intersperse (br [] [])
          )
{-        (tag.parentTags
            |> List.map (viewContentDiv Nothing)
            |> List.intersperse (hr [] [])
        )-}



tagToText: String -> Html Msg
tagToText tagId =
    a [ href ("/tags/" ++ tagId) ] [
    text tagId ]