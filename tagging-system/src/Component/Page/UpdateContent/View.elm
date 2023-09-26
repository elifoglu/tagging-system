module UpdateContent.View exposing (viewUpdateContentDiv)

import App.Model exposing (CreateContentPageModel, Model, UpdateContentPageData)
import App.Msg exposing (ContentInputType(..), Msg(..), PreviewContentModel(..))
import Content.Model exposing (Content)
import Content.View exposing (viewContentDiv)
import DataResponse exposing (ContentID)
import Html exposing (Html, br, button, div, hr, input, text, textarea)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)


viewUpdateContentDiv : UpdateContentPageData -> Maybe Content -> ContentID -> Html Msg
viewUpdateContentDiv updateContentPageData maybeContentToPreview contentId =
    div [] <|
        List.intersperse (br [] [])
            [ viewDisabledInput "text" (String.fromInt contentId)
            , viewInput "text" "title (empty if does not exist)" updateContentPageData.title (ContentInputChanged Title)
            , viewInput "text" "tagNames (use comma to separate)" updateContentPageData.tags (ContentInputChanged Tags)
            , viewContentTextArea "content" updateContentPageData.text (ContentInputChanged Text)
            , div []
                [ viewPreviewContentButton (PreviewContent <| PreviewForContentUpdate contentId updateContentPageData)
                , viewUpdateContentButton <| UpdateContent contentId updateContentPageData
                ]
            , hr [] []
            , case maybeContentToPreview of
                Just content ->
                    viewContentDiv Nothing content

                Nothing ->
                    text "invalid content, or no content at all"
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


viewPreviewContentButton : msg -> Html msg
viewPreviewContentButton msg =
    button [ onClick msg ] [ text "preview content" ]

