module CreateTag.View exposing (viewCreateTagDiv)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Model)
import App.Msg exposing (Msg(..), TagInputType(..))
import Html exposing (Html, br, button, div, input, label, span, text)
import Html.Attributes exposing (checked, placeholder, selected, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)


viewCreateTagDiv : CreateTagModuleModel -> Html Msg
viewCreateTagDiv createTagPageModel =
    div [] <|
        List.intersperse (br [] [])
            [ viewInput "text" "name" createTagPageModel.name (createTagInputMessage Name)
            , viewCreateTagButton CreateTag
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


createTagInputMessage : (eitherStringOrBool -> TagInputType) -> eitherStringOrBool -> Msg
createTagInputMessage a b =
    CreateTagModuleInputChanged (a b)


viewCheckBox : String -> Bool -> (Bool -> msg) -> Html msg
viewCheckBox i s toMsg =
    span []
        [ label [] [ text i ]
        , input [ type_ "checkbox", checked s, onCheck toMsg ] []
        ]


viewCreateTagButton : msg -> Html msg
viewCreateTagButton msg =
    button [ onClick msg ] [ text "create new tag" ]
