module SearchBox.View exposing (viewSearchBoxDiv)

import App.Model exposing (Initializable(..), Model, Page(..))
import App.Msg exposing (Msg(..))
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, type_, value)
import Html.Events exposing (onInput)

viewSearchBoxDiv : Page -> Html Msg
viewSearchBoxDiv activePage =
    case activePage of
        ContentSearchPage _ _ _ ->
            text ""

        _ ->
            div [ class "searchBoxInHeader" ]
                [ input [ type_ "text", class "contentSearchInput", placeholder "search >", value "", onInput GotSearchInput ] [] ]
