module UpdateContent.View exposing (viewUpdateContentDiv)

import App.Model exposing (CreateContentModuleModel, Model, UpdateContentModuleModel)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), WorkingOnWhichModule(..))
import Html exposing (Html, b, br, button, div, i, input, text, textarea)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)


viewUpdateContentDiv : UpdateContentModuleModel -> Html Msg
viewUpdateContentDiv updateContentModuleModel =
    div [] <|
        List.intersperse (br [] [])
            [ b [] [ text "update content: ", i [] [ text updateContentModuleModel.contentId ] ]
            , viewInput "text" "title" updateContentModuleModel.title (UpdateContentModuleInputChanged Title)
            , viewContentTextArea "content*" updateContentModuleModel.text (UpdateContentModuleInputChanged Text)
            , viewTagPickerDiv updateContentModuleModel.tagPickerModelForTags WorkingOnUpdateContentModule
            , viewUpdateContentButton <| UpdateContent
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "100px" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ placeholder p, value v, onInput toMsg, style "width" "300px", style "height" "100px" ] []


viewUpdateContentButton : msg -> Html msg
viewUpdateContentButton msg =
    button [ onClick msg ] [ text "✓" ]

