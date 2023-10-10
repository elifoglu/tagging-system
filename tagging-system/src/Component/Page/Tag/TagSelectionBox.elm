module Tag.TagSelectionBox exposing (viewTagSelectionBoxDiv)

import App.Msg exposing (Msg(..))
import Dict
import Html exposing (Html, b, div, option, text)
import Html.Attributes exposing (selected, style, value)
import Html.Events exposing (on, targetValue)
import Html.Keyed as Keyed
import Json.Decode as Json
import Tag.Model exposing (Tag)


type alias SelectTagConfig a msg =
    { onSelect : a -> msg
    , toString : a -> String
    , selected : a
    , tags : List a
    }


viewTagSelectionBoxDiv : List Tag -> Tag -> Html Msg
viewTagSelectionBoxDiv allTags activeTag =
    div [ style "margin-top" "20px" ]
        [ b [] [ text "go to tag" ], selectTag
            { onSelect = ChangeTagSelection
            , toString = tagToTagName
            , selected = activeTag
            , tags = allTags
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


tagToTagName : Tag -> String
tagToTagName tag =
    tag.name