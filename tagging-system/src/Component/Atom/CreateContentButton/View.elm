module CreateContentButton.View exposing (viewCreateContentButton)

import App.Model exposing (Initializable(..), Model, Page(..))
import App.Msg exposing (Msg(..))
import Html exposing (Html, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


viewCreateContentButton : Model -> Html Msg
viewCreateContentButton model =
    case model.activePage of
        TagPage (Initialized a) ->
            button [ class "createContentButtonInHeader", onClick (ToggleCreateContentModule (not a.createContentModule.isVisible)) ]
                [ text "+C"
                ]

        _ ->
            text ""
