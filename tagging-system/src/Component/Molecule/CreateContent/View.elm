module CreateContent.View exposing (viewCreateContentDiv)

import App.Model exposing (CreateContentModuleModel, Model)
import App.Msg exposing (ContentInputTypeForContentCreation(..), Msg(..))
import Html exposing (Html, br, button, div, input, text, textarea)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)


viewCreateContentDiv : CreateContentModuleModel -> Html Msg
viewCreateContentDiv createContentModuleModel =
    div [] <|
        [ text ""
        ]
            ++ List.intersperse (br [] [])
                [ viewInput "text" "title (empty if does not exist)" createContentModuleModel.title (CreateContentModuleInputChanged Title)
                , viewInput "text" "tagNames (use comma to separate)" createContentModuleModel.tags (CreateContentModuleInputChanged Tags)
                , viewContentTextArea "content" createContentModuleModel.text (CreateContentModuleInputChanged Text)
                , viewCreateContentButton CreateContent
                ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "200px" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ placeholder p, value v, onInput toMsg, style "width" "200px", style "height" "50px" ] []


viewCreateContentButton : msg -> Html msg
viewCreateContentButton msg =
    button [ onClick msg ] [ text "create new content" ]
