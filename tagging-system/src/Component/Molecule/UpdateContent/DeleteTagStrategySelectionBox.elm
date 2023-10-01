module UpdateContent.DeleteTagStrategySelectionBox exposing (..)

import App.Model exposing (TagDeleteStrategyChoice(..))
import App.Msg exposing (Msg(..))
import Dict
import Html exposing (Html, div, option, text)
import Html.Attributes exposing (disabled, selected, value)
import Html.Events exposing (on, targetValue)
import Html.Keyed as Keyed
import Json.Decode as Json


type alias SelectTagConfig a msg =
    { onSelect : a -> msg
    , toString : a -> String
    , selected : Maybe a
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
                        , selected (Just (cfg.toString tag) == Maybe.map cfg.toString cfg.selected)
                        ]
                        [ text (cfg.toString tag) ]
                    )
                )
                cfg.tags

        addEmpty opts =
            case cfg.selected of
                Nothing ->
                    ( "default option", option [ disabled True, selected True ] [ text "by strategy" ] ) :: opts

                Just _ ->
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


customToString : TagDeleteStrategyChoice -> String
customToString val =
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


viewDeleteTagStrategySelectionBoxDiv : Maybe TagDeleteStrategyChoice -> Html Msg
viewDeleteTagStrategySelectionBoxDiv maybeDeleteOption =
    div []
        [ selectTag
            { onSelect = ChangeTagDeleteStrategySelection
            , toString = customToString
            , selected = maybeDeleteOption
            , tags = allCustomTags
            }
        ]



{-

   update : Msg -> Model -> Model
   update msg model =
       case msg of
           ChangeSelection selection ->
               { model | selected = Just selection }


   initialModel : Model
   initialModel =
       { selected = Nothing }
-}
