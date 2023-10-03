module TagTextPart.View exposing (viewTextPart)

import App.Model exposing (..)
import App.Msg exposing (KeyDownPlace(..), Msg(..))
import Content.Model exposing (Content)
import DataResponse exposing (TagID)
import Html exposing (Attribute, Html, a, b, div, hr, img, input, span, text)
import Html.Attributes exposing (class, href, id, placeholder, src, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Html.Events.Extra.Mouse as Mouse exposing (Button(..), Event)
import Json.Decode exposing (map)
import List.Extra
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import Tuple exposing (second)


viewTextPart : Model -> Tag -> QuickContentEditModel -> TagTextPart -> Html Msg
viewTextPart model baseTag quickContentEditModel tagTextPart =
    div []
        [ viewTagAsATitle baseTag tagTextPart
        , viewContentsLineByLine model tagTextPart baseTag.tagId quickContentEditModel
        ]


viewTagAsATitle : Tag -> TagTextPart -> Html Msg
viewTagAsATitle baseTag tagTextPart =
    if tagTextPart.tag.tagId /= baseTag.tagId then
        span [ class "tagAsATitle" ] [ a [ href ("/tags/" ++ tagTextPart.tag.tagId) ] [ text ("#" ++ tagTextPart.tag.name) ] ]

    else
        text ""


viewContentsLineByLine : Model -> TagTextPart -> TagID -> QuickContentEditModel -> Html Msg
viewContentsLineByLine model currentTagTextPart tagIdOfTagPage quickContentEditModel =
    div []
        (currentTagTextPart.contents
            |> List.map (viewContentLineWithAllStuff model currentTagTextPart tagIdOfTagPage quickContentEditModel)
        )


viewContentLineWithAllStuff : Model -> TagTextPart -> TagID -> QuickContentEditModel -> Content -> Html Msg
viewContentLineWithAllStuff model currentTagTextPart tagIdOfTagPage quickContentEditModel content =
    div []
        [ viewContentSeparatorAdder model content Top
        , viewTopDownHrLineOfContent model content currentTagTextPart Top
        , viewContentLineOrQuickContentEditBox model currentTagTextPart tagIdOfTagPage quickContentEditModel content
        , viewTopDownHrLineOfContent model content currentTagTextPart Down
        , viewContentSeparatorAdder model content Down
        ]


viewContentLineOrQuickContentEditBox : Model -> TagTextPart -> TagID -> QuickContentEditModel -> Content -> Html Msg
viewContentLineOrQuickContentEditBox model currentTagTextPart tagIdOfTagPage quickContentEditModel content =
    case quickContentEditModel of
        Open opened txt ->
            if opened.contentId == content.contentId && opened.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                div [ class "quickContentEditDiv" ]
                    [ viewQuickContentEditInput txt
                    ]

            else
                viewContentLine model currentTagTextPart tagIdOfTagPage content

        ClosedButTextToStore _ _ ->
           viewContentLine model currentTagTextPart tagIdOfTagPage content


viewContentLine : Model -> TagTextPart -> TagID -> Content -> Html Msg
viewContentLine model currentTagTextPart tagIdOfTagPage content =
    div [ class "contentLineParent", onMouseDown model content tagIdOfTagPage currentTagTextPart.contents, onMouseOver content, onMouseLeave, onMouseDoubleClick content ]
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


viewContentSeparatorAdder : Model -> Content -> WhichHrLine -> Html Msg
viewContentSeparatorAdder model content whichHrLine =
    case model.activePage of
        TagPage (Initialized tagPage) ->
            case tagPage.quickContentAdderModule of
                JustQuickContentAdderData boxLocation text ->
                    if
                        boxLocation.contentLineContentId
                            == content.contentId
                            && boxLocation.contentLineTagId
                            == content.tagIdOfCurrentTextPart
                            && ((whichHrLine == Top && boxLocation.locatedAt == BeforeContentLine) || (whichHrLine == Down && boxLocation.locatedAt == AfterContentLine))
                    then
                        div [ class "quickContentAdderDiv" ]
                            [ viewQuickContentAdder text
                            ]

                    else
                        viewSeparatorForQuickContentAdder model content whichHrLine (Just boxLocation)

                NothingButTextToStore _ ->
                    viewSeparatorForQuickContentAdder model content whichHrLine Nothing

        _ ->
            text ""


viewSeparatorForQuickContentAdder : Model -> Content -> WhichHrLine -> Maybe QuickContentAdderLocation -> Html Msg
viewSeparatorForQuickContentAdder model content whichHrLine maybeQuickContentAdderLocation =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just _ ->
            text ""

        Nothing ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentWhichCursorIsOnItNow ->
                    if
                        (contentWhichCursorIsOnItNow.contentId == content.contentId)
                            && (contentWhichCursorIsOnItNow.tagId == content.tagIdOfCurrentTextPart)
                    then
                        if contentWhichCursorIsOnItNow.offsetPosY < topOffsetForContentLine && whichHrLine == Top then
                            let
                                showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator =
                                    case maybeQuickContentAdderLocation of
                                        Nothing ->
                                            True

                                        Just quickContentAdderLocation ->
                                            case quickContentAdderLocation.nextLineContentId of
                                                Nothing ->
                                                    True

                                                Just nextLineContentIdOfOpenQuickContentAdder ->
                                                    if nextLineContentIdOfOpenQuickContentAdder == content.contentId && quickContentAdderLocation.contentLineTagId == content.tagIdOfCurrentTextPart then
                                                        if quickContentAdderLocation.locatedAt == AfterContentLine then
                                                            False

                                                        else
                                                            True

                                                    else
                                                        True
                            in
                            if showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator then
                                div [ class "separatorForQuickContentAdderDiv" ] [ hr [] [] ]

                            else
                                text ""

                        else if contentWhichCursorIsOnItNow.offsetPosY > downOffsetForContentLine && whichHrLine == Down then
                            let
                                showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator =
                                    case maybeQuickContentAdderLocation of
                                        Nothing ->
                                            True

                                        Just quickContentAdderLocation ->
                                            case quickContentAdderLocation.prevLineContentId of
                                                Nothing ->
                                                    True

                                                Just prevLineContentIdOfOpenQuickContentAdder ->
                                                    if prevLineContentIdOfOpenQuickContentAdder == content.contentId && quickContentAdderLocation.contentLineTagId == content.tagIdOfCurrentTextPart then
                                                        if quickContentAdderLocation.locatedAt == BeforeContentLine then
                                                            False

                                                        else
                                                            True

                                                    else
                                                        True
                            in
                            if showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator then
                                div [ class "separatorForQuickContentAdderDiv" ] [ hr [] [] ]

                            else
                                text ""

                        else
                            text ""

                    else
                        text ""

                Nothing ->
                    text ""


viewQuickContentAdder : String -> Html Msg
viewQuickContentAdder inputText =
    viewInput "quickContentAdder" "text" "add new content..." inputText QuickContentAdderInputChanged (KeyDown QuickContentAdderInput)


viewQuickContentEditInput : String -> Html Msg
viewQuickContentEditInput inputText =
    viewInput "quickEditBox" "text" "" inputText QuickContentEditInputChanged (KeyDown QuickContentEditInput)


viewInput : String -> String -> String -> String -> (String -> msg) -> (Int -> msg) -> Html msg
viewInput i t p v toMsg keyDownMsg =
    input [ type_ t, id i, placeholder p, value v, onInput toMsg, onKeyDown keyDownMsg ] []


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (map tagger keyCode)


viewTopDownHrLineOfContent : Model -> Content -> TagTextPart -> WhichHrLine -> Html Msg
viewTopDownHrLineOfContent model content currentTagTextPart whichHrLine =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just beingDraggedContent ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentWhichCursorIsOnItNow ->
                    if
                        (contentWhichCursorIsOnItNow.contentId == content.contentId)
                            && (contentWhichCursorIsOnItNow.tagId == content.tagIdOfCurrentTextPart)
                            && contentWhichCursorIsOnItNowIsNotSameWithDraggedContent beingDraggedContent contentWhichCursorIsOnItNow
                            && currentTextPartDoesNotHaveSameContentWithBeingDraggedContent beingDraggedContent currentTagTextPart
                            && beingDraggedContentIsNotAtNear whichHrLine currentTagTextPart beingDraggedContent contentWhichCursorIsOnItNow
                    then
                        if contentWhichCursorIsOnItNow.offsetPosY < topOffsetForContentLine && whichHrLine == Top then
                            div [ class "separatorDiv" ] [ hr [] [] ]

                        else if contentWhichCursorIsOnItNow.offsetPosY > downOffsetForContentLine && whichHrLine == Down then
                            div [ class "separatorDiv" ] [ hr [] [] ]

                        else
                            text ""

                    else
                        text ""

                Nothing ->
                    text ""

        Nothing ->
            text ""


onMouseDown : Model -> Content -> TagID -> List Content -> Attribute Msg
onMouseDown model content tagIdOfTagPage contentsOfCurrentTextPart =
    Mouse.onDown
        (\event ->
            case event.button of
                MainButton ->
                    case model.contentTagDuoWhichCursorIsOverItNow of
                        Just c ->
                            if c.offsetPosY < topOffsetForContentLine || c.offsetPosY > downOffsetForContentLine then
                                let
                                    locateAt =
                                        if c.offsetPosY < topOffsetForContentLine then
                                            BeforeContentLine

                                        else
                                            AfterContentLine

                                    indexOfContentOnItsTagTextPart : Int
                                    indexOfContentOnItsTagTextPart =
                                        Maybe.withDefault -1 (List.Extra.elemIndex content contentsOfCurrentTextPart)

                                    prevLineContent : Maybe Content
                                    prevLineContent =
                                        List.Extra.getAt (indexOfContentOnItsTagTextPart - 1) contentsOfCurrentTextPart

                                    prevLineContentId : Maybe String
                                    prevLineContentId =
                                        Maybe.map (\a -> a.contentId) prevLineContent

                                    nextLineContent : Maybe Content
                                    nextLineContent =
                                        List.Extra.getAt (indexOfContentOnItsTagTextPart + 1) contentsOfCurrentTextPart

                                    nextLineContentId : Maybe String
                                    nextLineContentId =
                                        Maybe.map (\a -> a.contentId) nextLineContent
                                in
                                ToggleQuickContentAdderBox content.contentId tagIdOfTagPage content.tagIdOfCurrentTextPart locateAt prevLineContentId nextLineContentId

                            else
                                SetContentTagIdDuoToDrag (Just (ContentTagIdDuo content.contentId content.tagIdOfCurrentTextPart))

                        Nothing ->
                            DoNothing

                _ ->
                    SetContentTagIdDuoToDrag Nothing
        )


onMouseDoubleClick : Content -> Attribute Msg
onMouseDoubleClick content =
    Mouse.onContextMenu
        (\_ ->
            OpenQuickContentEditInput content
        )


onMouseOver : Content -> Attribute Msg
onMouseOver content =
    Mouse.onMove
        (\event ->
            SetContentWhichCursorIsOverIt (Just (ContentTagIdDuoWithOffsetPosY content.contentId content.tagIdOfCurrentTextPart (second event.offsetPos)))
        )


onMouseLeave : Attribute Msg
onMouseLeave =
    Mouse.onLeave
        (\_ ->
            SetContentWhichCursorIsOverIt Nothing
        )
