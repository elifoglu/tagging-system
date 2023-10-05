module App.ThemeSelector exposing (viewThemeSelectorBoxDiv)

import App.Model exposing (TagTextViewType(..), Theme(..))
import App.Msg exposing (Msg(..))
import Dict
import Html exposing (Html, b, div, option, text)
import Html.Attributes exposing (class, selected, style, value)
import Html.Events exposing (on, targetValue)
import Html.Keyed as Keyed
import Json.Decode as Json


type alias SelectTagConfig a msg =
    { onSelect : a -> msg
    , toString : a -> String
    , selected : a
    , themes : List a
    }


viewThemeSelectorBoxDiv : Theme -> Html Msg
viewThemeSelectorBoxDiv theme =
    div [ class "themeSelector", style "margin-top" "20px" ]
        [ selectTag
            { onSelect = ThemeChanged
            , toString = tagTextViewTypeToTextToShow
            , selected = theme
            , themes = allThemes
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
                cfg.themes

        addEmpty opts =
            opts

        tagsDict =
            List.map (\tag -> ( cfg.toString tag, tag )) cfg.themes |> Dict.fromList

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


tagTextViewTypeToTextToShow : Theme -> String
tagTextViewTypeToTextToShow theme =
    case theme of
        Light ->
            "light"

        Dark ->
            "dark"


allThemes : List Theme
allThemes =
    [ Light, Dark ]
