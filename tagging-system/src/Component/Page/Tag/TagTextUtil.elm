module Tag.TagTextUtil exposing (viewTagText)

import App.Msg exposing (Msg)
import Html exposing (Html, br, div, text)
import Html.Attributes exposing (class)
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import TagTextPart.View exposing (viewTextPart)


viewTagText : Tag -> List TagTextPart -> Html Msg
viewTagText tag tagTextParts =
    div [ class "tagTextView contentFont" ]
        (tagTextParts
            |> List.filter (\ttp -> not (List.isEmpty ttp.contents))
            |> List.map (viewTextPart tag)
            |> List.intersperse separatorLine
        )


separatorLine : Html Msg
separatorLine =
    br [] []