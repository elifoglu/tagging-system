module Tag.TagTextUtil exposing (viewTagText)

import App.Model exposing (TagTextViewType(..))
import App.Msg exposing (Msg)
import Html exposing (Html, br, div, text)
import Html.Attributes exposing (class)
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import TagTextPart.View exposing (viewTextPart)


viewTagText : Tag -> List TagTextPart -> List TagTextPart ->  List TagTextPart -> TagTextViewType -> Html Msg
viewTagText tag tagTextPartsForGroupView tagTextPartsForLineView tagTextPartsForDistinctGroupView activeTagTextViewType =
    case activeTagTextViewType of
        GroupView ->
            div [ class "tagTextView contentFont" ]
                (tagTextPartsForGroupView
                    |> List.filter (\ttp -> not (List.isEmpty ttp.contents))
                    |> List.map (viewTextPart tag)
                    |> List.intersperse separatorLine
                )

        LineView ->
            div [ class "tagTextView contentFont" ]
                (tagTextPartsForLineView
                    |> List.filter (\ttp -> not (List.isEmpty ttp.contents))
                    |> List.map (viewTextPart tag)
                    |> List.intersperse separatorLine
                )

        DistinctGroupView ->
            div [ class "tagTextView contentFont" ]
                (tagTextPartsForDistinctGroupView
                    |> List.filter (\ttp -> not (List.isEmpty ttp.contents))
                    |> List.map (viewTextPart tag)
                    |> List.intersperse separatorLine
                )


separatorLine : Html Msg
separatorLine =
    div []
        [ br [] []
        ]
