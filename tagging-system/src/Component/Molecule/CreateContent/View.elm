module CreateContent.View exposing (viewCreateContentDiv)

import App.Model exposing (CreateContentModuleModel, Model)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), WorkingOnWhichModule(..))
import Html exposing (Html, b, br, button, div, input, text, textarea)
import Html.Attributes exposing (class, placeholder, spellcheck, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)


viewCreateContentDiv : CreateContentModuleModel -> Html Msg
viewCreateContentDiv createContentModuleModel =
    div [] <|
        List.intersperse (br [] [])
            [ b [] [ text "create new content" ]
            , viewInput "text" "title" createContentModuleModel.title (CreateContentModuleInputChanged Title)
            , viewContentTextArea "content*" createContentModuleModel.text (CreateContentModuleInputChanged Text)
            , viewTagPickerDiv createContentModuleModel.tagPickerModelForTags WorkingOnCreateContentModule
            , viewCreateContentButton CreateContent
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "200px" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ spellcheck False, placeholder p, value v, onInput toMsg, style "width" "200px", style "height" "50px" ] []


viewCreateContentButton : msg -> Html msg
viewCreateContentButton msg =
    button [ class "createUpdateContentTagButtons", onClick msg ] [ b [] [ text "+" ] ]
