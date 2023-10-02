module TagTextPart.View exposing (viewTextPart)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import DataResponse exposing (TagID)
import Html exposing (Attribute, Html, a, br, div, hr, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse exposing (Button(..), Event)
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import Tuple exposing (second)


viewTextPart : Model -> Tag -> TagTextPart -> Html Msg
viewTextPart model baseTag tagTextPart =
    div []
        [ viewTagAsATitle baseTag tagTextPart
        , viewContentsLineByLine model tagTextPart.contents tagTextPart.tag.tagId
        ]


viewTagAsATitle : Tag -> TagTextPart -> Html Msg
viewTagAsATitle baseTag tagTextPart =
    if tagTextPart.tag.tagId /= baseTag.tagId then
        span [ class "tagAsATitle" ] [ a [ href ("/tags/" ++ tagTextPart.tag.tagId) ] [ text ("#" ++ tagTextPart.tag.name) ] ]

    else
        text ""


viewContentsLineByLine : Model -> List Content -> TagID -> Html Msg
viewContentsLineByLine model contents tagId =
    div []
        (contents
            |> List.map (viewContentLine model tagId)
        )


viewContentLine : Model -> TagID -> Content -> Html Msg
viewContentLine model tagId content =
    div [ onMouseDown content tagId, onMouseOver content tagId, onMouseLeave ]
        [ viewTopDownHrLineOfContent model content Top
        , div [ class "contentLineParent" ]
            [ div [ class "contentLineFirstChild" ]
                [ span [ class "contentLine" ]
                    [ text (" • " ++ content.text)
                    ]
                ]
            , div [ class "contentLineSecondChild" ]
                [ img
                    [ class "contentEditAndDeleteIcons", onClick (ToggleUpdateContentModuleFor content), style "margin-left" "5px", src "/edit.png" ]
                    []
                , img
                    [ class "contentEditAndDeleteIcons", onClick (DeleteContent content), style "margin-left" "5px", src "/delete.png" ]
                    []
                ]
            ]
        , viewTopDownHrLineOfContent model content Down
        ]


type WhichHrLine
    = Top
    | Down

--this lines are just to show for content drag feature
viewTopDownHrLineOfContent : Model -> Content -> WhichHrLine -> Html Msg
viewTopDownHrLineOfContent model content whichHrLine =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just _ ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentTagIdDuoWithOffsetY ->
                    if contentTagIdDuoWithOffsetY.contentId == content.contentId then
                        if contentTagIdDuoWithOffsetY.offsetPosY < 3 && whichHrLine == Top then
                            div [ class "separatorDiv" ] [ hr [ class "separator" ] [] ]

                        else if contentTagIdDuoWithOffsetY.offsetPosY > 14 && whichHrLine == Down then
                            div [ class "separatorDiv" ] [ hr [ class "separator" ] [] ]

                        else
                            text ""

                    else
                        text ""

                Nothing ->
                    text ""

        Nothing ->
            text ""


onMouseDown : Content -> TagID -> Attribute Msg
onMouseDown content tagId =
    Mouse.onDown
        (\event ->
            case event.button of
                MainButton ->
                    SetContentTagIdDuoToDrag (Just (ContentTagIdDuo content.contentId tagId))

                _ ->
                    SetContentTagIdDuoToDrag Nothing
        )


onMouseOver : Content -> TagID -> Attribute Msg
onMouseOver content tagId =
    Mouse.onMove
        (\event ->
            SetContentWhichCursorIsOverIt (Just (ContentTagIdDuoWithOffsetPosY content.contentId tagId (second event.offsetPos)))
        )


onMouseLeave : Attribute Msg
onMouseLeave =
    Mouse.onLeave
        (\_ ->
            SetContentWhichCursorIsOverIt Nothing
        )
