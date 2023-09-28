module CreateContent.View exposing (viewCreateContentDiv)

import App.Model exposing (CreateContentPageModel, Model)
import App.Msg exposing (ContentInputType(..), Msg(..), PreviewContentModel(..))
import Content.View exposing (viewContentDiv)
import Html exposing (Html, br, button, div, hr, input, span, text, textarea)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)


viewCreateContentDiv : CreateContentPageModel -> Html Msg
viewCreateContentDiv createContentPageModel =
    div [] <|
        [ text ""
        ]
            ++ List.intersperse (br [] [])
                [ viewInput "text" "id" createContentPageModel.id (ContentInputChanged Id)
                , viewInput "text" "title (empty if does not exist)" createContentPageModel.title (ContentInputChanged Title)
                , viewInput "text" "tagNames (use comma to separate)" createContentPageModel.tags (ContentInputChanged Tags)
                , span [] [ text "!!don't forget to add search text manually if you will give a reference to ekşi/medium instead of bringing the full text here!!" ]
                , viewContentTextArea "content" createContentPageModel.text (ContentInputChanged Text)
                , div []
                    [ viewPreviewContentButton (PreviewContent <| PreviewForContentCreate createContentPageModel)
                    , viewCreateContentButton (CreateContent createContentPageModel)
                    ]
                , hr [] []
                , case createContentPageModel.maybeContentToPreview of
                    Just content ->
                        viewContentDiv Nothing content

                    Nothing ->
                        text "invalid content, or no content at all"
                ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg, style "width" "1000px" ] []


viewContentTextArea : String -> String -> (String -> msg) -> Html msg
viewContentTextArea p v toMsg =
    textarea [ placeholder p, value v, onInput toMsg, style "width" "1000px", style "height" "500px" ] []


viewCreateContentButton : msg -> Html msg
viewCreateContentButton msg =
    button [ onClick msg ] [ text "create new content" ]


viewPreviewContentButton : msg -> Html msg
viewPreviewContentButton msg =
    button [ onClick msg ] [ text "preview content" ]