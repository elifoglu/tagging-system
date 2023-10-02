module Tag.TagTextTypeSelectionBox exposing (viewTagTextTypeSelectionBoxDiv)

import App.Model exposing (TagTextViewType(..))
import App.Msg exposing (Msg(..))
import Dict
import Html exposing (Html, div, option, text)
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


viewTagTextTypeSelectionBoxDiv : TagTextViewType -> Html Msg
viewTagTextTypeSelectionBoxDiv deleteStrategy =
    div [ style "margin-bottom" "20px" ]
        [ selectTag
            { onSelect = ChangeTagTextViewTypeSelection
            , toString = tagTextViewTypeToTextToShow
            , selected = deleteStrategy
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
        LineView ->
            "line"

        DistinctGroupView ->
            "group with distinct contents"


allViewTypes : List TagTextViewType
allViewTypes =
    [ GroupView, LineView, DistinctGroupView ]