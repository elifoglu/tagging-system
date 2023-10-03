module Tag.TagTextUtil exposing (viewTagText)

import App.Model exposing (Model, QuickContentEditModel, TagTextViewType(..))
import App.Msg exposing (Msg)
import Html exposing (Html, br, div, text)
import Html.Attributes exposing (class)
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import TagTextPart.View exposing (viewTextPart)


viewTagText : Model -> Tag -> List TagTextPart -> List TagTextPart -> List TagTextPart -> TagTextViewType -> QuickContentEditModel -> Html Msg
viewTagText model tag tagTextPartsForGroupView tagTextPartsForLineView tagTextPartsForDistinctGroupView activeTagTextViewType quickContentEditModel =
    let
        tagTextParts =
            case activeTagTextViewType of
                GroupView ->
                    tagTextPartsForGroupView

                LineView ->
                    tagTextPartsForLineView

                DistinctGroupView ->
                    tagTextPartsForDistinctGroupView
    in
    div [ class "tagTextView contentFont" ]
        (tagTextParts
            |> List.filter (\ttp -> not (List.isEmpty ttp.contents))
            |> List.map (viewTextPart model tag quickContentEditModel)
            |> List.intersperse separatorLine
        )


separatorLine : Html Msg
separatorLine =
    div []
        [ br [] []
        ]
