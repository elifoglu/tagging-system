module CreateTagButton.View exposing (viewCreateTagButton)

import App.Model exposing (Initializable(..), Model, Page(..))
import App.Msg exposing (Msg(..))
import Html exposing (Html, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


viewCreateTagButton : Model -> Html Msg
viewCreateTagButton model =
    case model.activePage of
        TagPage (Initialized a) ->
            button [ class "createTagButtonInHeader", onClick (ToggleCreateTagModule (not a.createTagModule.isVisible)) ]
                [ text "T" ]

        _ ->
            text ""
