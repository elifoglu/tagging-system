module UpdateTag.View exposing (viewUpdateTagDiv)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, Model, UpdateTagPageModel)
import App.Msg exposing (ContentInputType(..), Msg(..), PreviewContentModel(..), TagInputType(..))
import Html exposing (Html, br, button, div, input, text)
import Html.Attributes exposing (placeholder, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)


viewUpdateTagDiv : UpdateTagPageModel -> String -> Html Msg
viewUpdateTagDiv updateTagPageModel tagId =
    div [] <|
        List.intersperse (br [] [])
            [ viewDisabledInput "text" tagId
            , viewInput "text" "infoContentId" updateTagPageModel.infoContentId (\contentId -> TagInputChanged <| InfoContentId contentId)
            , div []
                [ viewUpdateTagButton (UpdateTag tagId updateTagPageModel)
                ]
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "1000px" ] []


viewDisabledInput : String -> String -> Html msg
viewDisabledInput t v =
    input [ type_ t, value v, style "width" "1000px", style "enabled" "false" ] []


viewUpdateTagButton : msg -> Html msg
viewUpdateTagButton msg =
    button [ onClick msg ] [ text "update tag" ]
