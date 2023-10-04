module Component.KeydownHandler exposing (onKeyDown)

import App.Msg exposing (KeyDownPlace(..), KeyDownType(..), Msg(..))
import Html exposing (Attribute, Html)
import Html.Events exposing (on)
import Json.Decode exposing (bool, field, int, map, map2)
import Tuple

onKeyDown : (KeyDownType -> msg) -> Attribute msg
onKeyDown msgFn =
    let
        tagger : ( number, Bool ) -> msg
        tagger ( code, shift ) =
            if code == 27 then
                msgFn Escape

            else if code == 13 && shift then
                msgFn ShiftEnter

            else if code == 13 then
                msgFn Enter

            else
                msgFn OtherSoNoOp

        keyExtractor =
            map2 Tuple.pair
                (field "keyCode" int)
                (field "shiftKey" bool)
    in
    on "keydown" <| map tagger keyExtractor