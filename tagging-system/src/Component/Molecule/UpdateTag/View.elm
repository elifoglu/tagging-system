module UpdateTag.View exposing (viewUpdateTagDiv)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Model, TagModuleVisibility(..), UpdateTagModuleModel)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), TagInputType(..), WorkingOnWhichModule(..))
import Html exposing (Html, b, br, button, div, i, img, input, span, text)
import Html.Attributes exposing (class, placeholder, selected, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)


viewUpdateTagDiv : UpdateTagModuleModel -> Html Msg
viewUpdateTagDiv updateTagModuleModel =
    div [ class "createOrUpdateTagDiv" ] <|
        List.intersperse (br [] [])
            [ b [] [ text "update tag: ", i [] [ text updateTagModuleModel.tagId ] ]
            , viewInput "text" "name" updateTagModuleModel.name (\contentId -> UpdateTagModuleInputChanged <| Name contentId)
            , viewInput "text" "description" updateTagModuleModel.description (\contentId -> UpdateTagModuleInputChanged <| Description contentId)
            , viewTagPickerDiv updateTagModuleModel.tagPickerModelForParentTags WorkingOnUpdateTagModule
            , div [ class "updateOrDeleteTagButtonParentDiv" ]
                [ viewUpdateTagButton UpdateTag
                , viewDeleteTagButton DeleteTag
                ]
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


viewUpdateTagButton : msg -> Html msg
viewUpdateTagButton msg =
    div [ class "updateOrDeleteTagButtonDiv" ]
        [ button [ onClick msg ] [ text "✓" ]
        ]


viewDeleteTagButton : msg -> Html msg
viewDeleteTagButton msg =
    div [ class "updateOrDeleteTagButtonDiv" ]
        [ img [ class "deleteTagIcon", onClick msg, style "margin-left" "5px", src "/delete.png" ]
            []
        ]
