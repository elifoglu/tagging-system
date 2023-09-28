module CreateContentButton.View exposing (viewCreateContentButton)

import App.Msg exposing (Msg(..))
import Html exposing (Html, a, button, text)
import Html.Attributes exposing (class, href)


viewCreateContentButton : Html Msg
viewCreateContentButton =
    button [ class "createContentButtonInHeader" ]
        [ a
            [ href "/create/content"
            ]
            [ text "+C" ]
        ]
