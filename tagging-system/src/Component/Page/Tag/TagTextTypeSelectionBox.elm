module Tag.TagTextTypeSelectionBox exposing (viewTagTextViewTypeSelectionBoxDiv)

import App.Model exposing (TagTextViewType(..))
import App.Msg exposing (Msg(..))
import Dict
import Html exposing (Html, b, div, option, text)
import Html.Attributes exposing (selected, style, value)
import Html.Events exposing (on, targetValue)
import Html.Keyed as Keyed
import Json.Decode as Json


type alias SelectTagConfig a msg =
    { onSelect : a -> msg
    , toString : a -> String
    , selected : a
    , tags : List a
    }


viewTagTextViewTypeSelectionBoxDiv : TagTextViewType -> Html Msg
viewTagTextViewTypeSelectionBoxDiv activeViewType =
    div [ style "margin-top" "20px" ]
        [ b [] [ text "view type" ], selectTag
            { onSelect = ChangeTagTextViewTypeSelection
            , toString = tagTextViewTypeToTextToShow
            , selected = activeViewType
            , tags = allViewTypes
            }
        ]


selectTag : SelectTagConfig a msg -> Html msg
selectTag cfg =
    let
        options =
            List.map
                (\tag ->
                    ( cfg.toString tag
                    , option
                        [ value (cfg.toString tag)
                        , selected (tag == cfg.selected)
                        ]
                        [ text (cfg.toString tag) ]
                    )
                )
                cfg.tags

        addEmpty opts =
            opts

        tagsDict =
            List.map (\tag -> ( cfg.toString tag, tag )) cfg.tags |> Dict.fromList

        decoder =
            targetValue
                |> Json.andThen
                    (\val ->
                        case Dict.get val tagsDict of
                            Nothing ->
                                Json.fail ""

                            Just tag ->
                                Json.succeed tag
                    )
                |> Json.map cfg.onSelect
    in
    Keyed.node "select" [ on "change" decoder ] (addEmpty options)


tagTextViewTypeToTextToShow : TagTextViewType -> String
tagTextViewTypeToTextToShow val =
    case val of
        GroupView ->
            "group"

        DistinctGroupView ->
            "distinct"

        LineView ->
            "condensed"




allViewTypes : List TagTextViewType
allViewTypes =
    [ GroupView, DistinctGroupView, LineView ]
