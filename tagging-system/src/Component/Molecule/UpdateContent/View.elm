module UpdateContent.View exposing (viewUpdateContentDiv)

import App.Model exposing (CreateContentModuleModel, Model, UpdateContentModuleModel)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), WorkingOnWhichModule(..))
import Content.Model exposing (Content)
import Content.Util exposing (createdDateOf, lastModifiedDateOf)
import Html exposing (Html, b, br, button, div, input, text, textarea)
import Html.Attributes exposing (class, placeholder, spellcheck, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)


viewUpdateContentDiv : UpdateContentModuleModel -> Html Msg
viewUpdateContentDiv updateContentModuleModel =
    div [] <|
        List.intersperse (br [] [])
            [ b [] [ text "update content" ]
            , viewContentDates updateContentModuleModel.content
            , viewInput "text" "title" updateContentModuleModel.title (UpdateContentModuleInputChanged Title)
            , viewContentTextArea "content*" updateContentModuleModel.text (UpdateContentModuleInputChanged Text)
            , viewTagPickerDiv updateContentModuleModel.tagPickerModelForTags WorkingOnUpdateContentModule
            , viewUpdateContentButton UpdateContent
            ]


viewContentDates : Content -> Html Msg
viewContentDates content =
    div [ class "contentInfoDivOnUpdateContentModule" ]
        [ text ("id: " ++ content.contentId)
        , br [] []
        , text ("created at: " ++ createdDateOf content)
        , br [] []
        , text ("modified at: " ++ lastModifiedDateOf content)
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "100px" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ spellcheck False, placeholder p, value v, onInput toMsg, style "width" "300px", style "height" "100px" ] []


viewUpdateContentButton : msg -> Html msg
viewUpdateContentButton msg =
    button [ class "createUpdateContentTagButtons", onClick msg ] [ text "✓" ]
