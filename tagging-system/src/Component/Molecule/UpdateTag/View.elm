module UpdateTag.View exposing (viewUpdateTagDiv)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Model, TagDeleteStrategyChoice, TagModuleVisibility(..), UpdateTagModuleModel)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), TagInputType(..), WorkingOnWhichModule(..))
import Html exposing (Html, b, br, button, div, hr, i, img, input, span, text)
import Html.Attributes exposing (class, placeholder, selected, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import TagPicker.View exposing (viewTagPickerDiv)
import UpdateContent.DeleteTagStrategySelectionBox exposing (viewDeleteTagStrategySelectionBoxDiv)


viewUpdateTagDiv : String -> UpdateTagModuleModel -> Html Msg
viewUpdateTagDiv homeTagId updateTagModuleModel =
    div [ class "createOrUpdateTagDiv" ] <|
        List.intersperse (br [] [])
            [ b [] [ text "update tag: ", i [] [ text updateTagModuleModel.tagId ] ]
            , viewInput "text" "name" updateTagModuleModel.name (\contentId -> UpdateTagModuleInputChanged <| Name contentId)
            , viewInput "text" "description" updateTagModuleModel.description (\contentId -> UpdateTagModuleInputChanged <| Description contentId)
            , viewTagPickerDiv updateTagModuleModel.tagPickerModelForParentTags WorkingOnUpdateTagModule
            , div [ class "updateOrDeleteTagButtonParentDiv" ]
                [ viewUpdateTagButton UpdateTag
                , viewDeleteBox homeTagId updateTagModuleModel
                ]
            ]


viewDeleteBox : String -> UpdateTagModuleModel -> Html Msg
viewDeleteBox homeTagId updateTagModuleModel =
    if homeTagId == updateTagModuleModel.tagId then
        text ""

    else
        div
            [ style "margin-top" "20px" ]
            [ b [] [ text "delete," ]
            , viewDeleteTagStrategySelectionBoxDiv updateTagModuleModel.tagDeleteStrategy
            , viewDeleteTagButton DeleteTag
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


viewUpdateTagButton : msg -> Html msg
viewUpdateTagButton msg =
    div []
        [ button [ class "createUpdateContentTagButtons", onClick msg ] [ text "✓" ]
        ]


viewDeleteTagButton : msg -> Html msg
viewDeleteTagButton msg =
    div []
        [ img [ class "deleteTagIcon", onClick msg, style "margin-left" "5px", src "/delete.png" ]
            []
        ]
