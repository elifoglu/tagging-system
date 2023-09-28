module CreateTagButton.View exposing (viewCreateTagButton)

import App.Msg exposing (Msg(..))
import Html exposing (Html, a, button, text)
import Html.Attributes exposing (class, href)


viewCreateTagButton : Html Msg
viewCreateTagButton =
    button [ class "createTagButtonInHeader" ]
        [ a
            [ href "/create/tag"
            ]
            [ text "+T" ]
        ]
