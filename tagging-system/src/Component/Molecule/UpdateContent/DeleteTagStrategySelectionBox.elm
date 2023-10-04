module UpdateContent.DeleteTagStrategySelectionBox exposing (viewDeleteTagStrategySelectionBoxDiv)

import App.Model exposing (TagDeleteStrategyChoice(..))
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
    Keyed.node "select" [ on "change" decoder, style "width" "108px" ] (addEmpty options)


selectionToString : TagDeleteStrategyChoice -> String
selectionToString val =
    case val of
        DeleteTheTagOnly ->
            "the tag only"

        DeleteTagAlongWithItsChildContents ->
            "w/ its child contents"

        DeleteTagAlongWithItsAllContents ->
            "w/ its all descendants"


allCustomTags : List TagDeleteStrategyChoice
allCustomTags =
    [ DeleteTheTagOnly, DeleteTagAlongWithItsChildContents, DeleteTagAlongWithItsAllContents ]


viewDeleteTagStrategySelectionBoxDiv : TagDeleteStrategyChoice -> Html Msg
viewDeleteTagStrategySelectionBoxDiv deleteStrategy =
    div []
        [ selectTag
            { onSelect = ChangeTagDeleteStrategySelection
            , toString = selectionToString
            , selected = deleteStrategy
            , tags = allCustomTags
            }
        ]