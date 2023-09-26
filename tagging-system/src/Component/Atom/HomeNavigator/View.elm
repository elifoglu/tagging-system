module HomeNavigator.View exposing (viewHomeNavigator)

import App.Msg exposing (Msg)
import Html exposing (Html, a, b, span, text)
import Html.Attributes exposing (class, href, style)
import App.Model exposing (Initializable(..), Model, Page(..))

viewHomeNavigator : Model -> Html Msg
viewHomeNavigator model =
    case model.activePage of
        TagPage initializable ->
            case initializable of
                NonInitialized _ ->
                    viewNavigator False

                Initialized initialized ->
                    viewNavigator (model.homeTagId == initialized.tag.tagId)

        _ ->
            viewNavigator False


viewNavigator : Bool -> Html Msg
viewNavigator currentTagIsHomeTag =
    if currentTagIsHomeTag then
        span [ class "homeNavigator", style "cursor" "pointer" ]
            [ b [ style "font-weight" "bolder" ]
                [ text "tagging-system" ]
            ]

    else
        a [ class "homeNavigator", href "/" ]
            [ b [ style "font-weight" "bolder" ]
                [ text "tagging-system" ]
            ]
