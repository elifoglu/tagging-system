module UpdateContent.View exposing (viewUpdateContentDiv)

import App.Model exposing (CreateContentModuleModel, Model, UpdateContentModuleData)
import App.Msg exposing (ContentInputTypeForContentCreation(..), ContentInputTypeForContentUpdate(..), Msg(..))
import DataResponse exposing (ContentID)
import Html exposing (Html, br, button, div, input, text, textarea)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)


viewUpdateContentDiv : UpdateContentModuleData -> ContentID -> Html Msg
viewUpdateContentDiv updateContentModuleData contentId =
    div [] <|
        List.intersperse (br [] [])
            [ viewDisabledInput "text" contentId
            , viewInput "text" "title (empty if does not exist)" updateContentModuleData.title (UpdateContentModuleInputChanged TitleU)
            , viewInput "text" "tagNames (use comma to separate)" updateContentModuleData.tags (UpdateContentModuleInputChanged TagsU)
            , viewContentTextArea "content" updateContentModuleData.text (UpdateContentModuleInputChanged TextU)
            , viewUpdateContentButton <| UpdateContent
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "1000px" ] []


viewDisabledInput : String -> String -> Html msg
viewDisabledInput t v =
    input [ type_ t, value v, style "width" "1000px", style "enabled" "false" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ placeholder p, value v, onInput toMsg, style "width" "1000px", style "height" "500px" ] []


viewUpdateContentButton : msg -> Html msg
viewUpdateContentButton msg =
    button [ onClick msg ] [ text "update content" ]

