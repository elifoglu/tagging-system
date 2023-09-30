module CreateTag.View exposing (viewCreateTagDiv)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Model)
import App.Msg exposing (Msg(..), TagInputType(..))
import Html exposing (Html, br, button, div, input, text)
import Html.Attributes exposing (placeholder, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)


viewCreateTagDiv : CreateTagModuleModel -> Html Msg
viewCreateTagDiv createTagModuleModel =
    div [] <|
        List.intersperse (br [] [])
            [ viewInput "text" "name" createTagModuleModel.name (createTagInputMessage Name)
            , viewInput "text" "description" createTagModuleModel.description (createTagInputMessage Description)
            , viewTagPickerDiv createTagModuleModel.tagPickerModelForParentTags
            , viewCreateTagButton CreateTag
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


createTagInputMessage : (eitherStringOrBool -> TagInputType) -> eitherStringOrBool -> Msg
createTagInputMessage a b =
    CreateTagModuleInputChanged (a b)


viewCreateTagButton : msg -> Html msg
viewCreateTagButton msg =
    button [ onClick msg ] [ text "create new tag" ]
