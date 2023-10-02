module TagTextPart.View exposing (viewTextPart)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import DataResponse exposing (TagID)
import Html exposing (Attribute, Html, a, b, div, hr, img, span, text)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse exposing (Button(..), Event)
import List.Extra
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import Tuple exposing (second)


viewTextPart : Model -> Tag -> TagTextPart -> Html Msg
viewTextPart model baseTag tagTextPart =
    div []
        [ viewTagAsATitle baseTag tagTextPart
        , viewContentsLineByLine model tagTextPart tagTextPart.tag.tagId
        ]


viewTagAsATitle : Tag -> TagTextPart -> Html Msg
viewTagAsATitle baseTag tagTextPart =
    if tagTextPart.tag.tagId /= baseTag.tagId then
        span [ class "tagAsATitle" ] [ a [ href ("/tags/" ++ tagTextPart.tag.tagId) ] [ text ("#" ++ tagTextPart.tag.name) ] ]

    else
        text ""


viewContentsLineByLine : Model -> TagTextPart -> TagID -> Html Msg
viewContentsLineByLine model currentTagTextPart tagId =
    div []
        (currentTagTextPart.contents
            |> List.map (viewContentLine model currentTagTextPart tagId)
        )


viewContentLine : Model -> TagTextPart -> TagID -> Content -> Html Msg
viewContentLine model currentTagTextPart tagId content =
    div [ onMouseDown content tagId, onMouseOver content tagId, onMouseLeave ]
        [ viewTopDownHrLineOfContent model content tagId currentTagTextPart Top
        , div [ class "contentLineParent" ]
            [ div [ class "contentLineFirstChild" ]
                [ span [ class "contentLine" ]
                    [ case model.contentTagIdDuoThatIsBeingDragged of
                        Just draggedContent ->
                            if content.contentId == draggedContent.contentId && currentTagTextPart.tag.tagId == draggedContent.tagId then
                                b [] [ text (" • " ++ content.text) ]

                            else
                                text (" • " ++ content.text)

                        Nothing ->
                            text (" • " ++ content.text)
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
        , viewTopDownHrLineOfContent model content tagId currentTagTextPart Down
        ]


type WhichHrLine
    = Top
    | Down


currentTextPartDoesNotHaveSameContentWithBeingDraggedContent : ContentTagIdDuo -> TagTextPart -> Bool
currentTextPartDoesNotHaveSameContentWithBeingDraggedContent beingDraggedContent currentTagTextPart =
    if currentTagTextPart.tag.tagId == beingDraggedContent.tagId then
        True

    else
        not (List.any (\content -> content.contentId == beingDraggedContent.contentId) currentTagTextPart.contents)


contentWhichCursorIsOnItNowIsNotSameWithDraggedContent : ContentTagIdDuo -> ContentTagIdDuoWithOffsetPosY -> Bool
contentWhichCursorIsOnItNowIsNotSameWithDraggedContent a b =
    not (a.contentId == b.contentId && a.tagId == b.tagId)


beingDraggedContentIsNotAtNear : WhichHrLine -> TagTextPart -> ContentTagIdDuo -> ContentTagIdDuoWithOffsetPosY -> Bool
beingDraggedContentIsNotAtNear whichHrLine tagTextPart beingDraggedContent possiblyNearContent =
    let
        beingDraggedContentIndex : Maybe Int
        beingDraggedContentIndex =
            List.Extra.findIndex (\c -> c.contentId == beingDraggedContent.contentId) tagTextPart.contents

        possiblyNearContentIndex : Maybe Int
        possiblyNearContentIndex =
            List.Extra.findIndex (\c -> c.contentId == possiblyNearContent.contentId) tagTextPart.contents

        result =
            case ( beingDraggedContentIndex, possiblyNearContentIndex ) of
                ( Just draggedIndexInList, Just nearIndexInList ) ->
                    if draggedIndexInList - nearIndexInList == 1 && whichHrLine == Down then
                        False

                    else if nearIndexInList - draggedIndexInList == 1 && whichHrLine == Top then
                        False

                    else
                        True

                _ ->
                    True
    in
    result


viewTopDownHrLineOfContent : Model -> Content -> String -> TagTextPart -> WhichHrLine -> Html Msg
viewTopDownHrLineOfContent model content tagIdOfTextPartThatContentBelongs currentTagTextPart whichHrLine =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just beingDraggedContent ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentWhichCursorIsOnItNow ->
                    if
                        (contentWhichCursorIsOnItNow.contentId == content.contentId)
                            && (contentWhichCursorIsOnItNow.tagId == tagIdOfTextPartThatContentBelongs)
                            && contentWhichCursorIsOnItNowIsNotSameWithDraggedContent beingDraggedContent contentWhichCursorIsOnItNow
                            && currentTextPartDoesNotHaveSameContentWithBeingDraggedContent beingDraggedContent currentTagTextPart
                            && beingDraggedContentIsNotAtNear whichHrLine currentTagTextPart beingDraggedContent contentWhichCursorIsOnItNow
                    then
                        if contentWhichCursorIsOnItNow.offsetPosY < 3 && whichHrLine == Top then
                            div [ class "separatorDiv" ] [ hr [ class "separator" ] [] ]

                        else if contentWhichCursorIsOnItNow.offsetPosY > 14 && whichHrLine == Down then
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
