module TagTextPart.View exposing (viewTextPart)

import App.Model exposing (..)
import App.Msg exposing (KeyDownPlace(..), KeyDownType(..), Msg(..))
import Component.ContentTextUtil exposing (contentHasLinkInside, createBeautifiedContentText)
import Component.KeydownHandler exposing (onKeyDown)
import Content.Model exposing (Content)
import DataResponse exposing (TagID)
import Html exposing (Attribute, Html, a, b, div, hr, img, span, text, textarea)
import Html.Attributes exposing (class, cols, href, id, placeholder, rows, spellcheck, src, style, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra.Mouse as Mouse exposing (Button(..), Event)
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
        [ viewContentSeparatorAdder model content Top currentTagTextPart.contents
        , viewDragDropSeparator model content currentTagTextPart Top
        , viewContentLineOrQuickContentEditBox model currentTagTextPart tagIdOfTagPage quickContentEditModel content
        , viewDragDropSeparator model content currentTagTextPart Down
        , viewContentSeparatorAdder model content Down currentTagTextPart.contents
        ]


viewContentLineOrQuickContentEditBox : Model -> TagTextPart -> TagID -> QuickContentEditModel -> Content -> Html Msg
viewContentLineOrQuickContentEditBox model currentTagTextPart tagIdOfTagPage quickContentEditModel content =
    case quickContentEditModel of
        Open opened txt ->
            if opened.contentId == content.contentId && opened.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                div []
                    [ viewQuickContentEditInput txt
                    ]

            else
                viewContentLine model currentTagTextPart tagIdOfTagPage content

        ClosedButTextToStore _ _ ->
            viewContentLine model currentTagTextPart tagIdOfTagPage content


viewContentLine : Model -> TagTextPart -> TagID -> Content -> Html Msg
viewContentLine model currentTagTextPart tagIdOfTagPage content =
    div [ class "contentLineParent" ]
        [ div [ class "contentLineFirstChild" ]
            [ span [ id (content.contentId ++ content.tagIdOfCurrentTextPart), onMouseDown model content tagIdOfTagPage currentTagTextPart.contents, onMouseOver model content, onMouseLeave, onRightClick content ]
                [ if String.trim content.text == "" then
                    span [ class "emptyContentLine" ] [ createBeautifiedContentText "&nbsp;" ]

                  else
                    span [ class "contentLine" ]
                        [ case model.contentTagIdDuoThatIsBeingDragged of
                            Just draggedContent ->
                                if content.contentId == draggedContent.contentId && currentTagTextPart.tag.tagId == draggedContent.tagId then
                                    --b [] [ updateContentTextWithClickableLinks (" • " ++ content.text) ]
                                    createBeautifiedContentText (" • " ++ content.text)

                                else
                                    createBeautifiedContentText (" • " ++ content.text)

                            Nothing ->
                                createBeautifiedContentText (" • " ++ content.text)
                        ]
                ]
            ]
        , div [ class "contentLineSecondChild" ]
            [ div [ class "iconHolderDivInSecondChild" ]
                [ if String.trim content.text == "" then
                    text ""

                  else
                    img
                        [ class "contentEditAndDeleteIcons", onClick (ToggleUpdateContentModuleFor content), style "margin-left" "5px", src "/edit.png" ]
                        []
                , img
                    [ class "contentEditAndDeleteIcons"
                    , onClick (DeleteContent content)
                    , style "margin-left" "5px"
                    , style "margin-right"
                        (if String.trim content.text == "" then
                            "250px"

                         else
                            "0px"
                        )
                    , src "/delete.png"
                    ]
                    []
                ]
            ]
        ]


type WhichHrLine
    = Top
    | Down


ifActiveViewTypeIsLineView : Model -> Bool
ifActiveViewTypeIsLineView model =
    case model.activePage of
        TagPage (Initialized t) ->
            t.activeTagTextViewType == LineView

        _ ->
            False


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


viewContentSeparatorAdder : Model -> Content -> WhichHrLine -> List Content -> Html Msg
viewContentSeparatorAdder model content whichHrLine contentsOfCurrentTextPart =
    case model.activePage of
        TagPage (Initialized tagPage) ->
            let
                maybeContentOfCurrentlyOpenQuickContentEditBox =
                    case tagPage.quickContentEditModule of
                        Open contentOfCurrentlyOpenQuickContentEditBox _ ->
                            Just contentOfCurrentlyOpenQuickContentEditBox

                        ClosedButTextToStore _ _ ->
                            Nothing
            in
            case tagPage.quickContentAdderModule of
                JustQuickContentAdderData boxLocation text ->
                    if
                        boxLocation.contentLineContentId
                            == content.contentId
                            && boxLocation.contentLineTagId
                            == content.tagIdOfCurrentTextPart
                            && ((whichHrLine == Top && boxLocation.locatedAt == BeforeContentLine) || (whichHrLine == Down && boxLocation.locatedAt == AfterContentLine))
                    then
                        div []
                            [ viewQuickContentAdder text
                            ]

                    else
                        viewSeparatorForQuickContentAdder model content whichHrLine (Just boxLocation) maybeContentOfCurrentlyOpenQuickContentEditBox contentsOfCurrentTextPart

                NothingButTextToStore _ ->
                    viewSeparatorForQuickContentAdder model content whichHrLine Nothing maybeContentOfCurrentlyOpenQuickContentEditBox contentsOfCurrentTextPart

        _ ->
            text ""


viewSeparatorForQuickContentAdder : Model -> Content -> WhichHrLine -> Maybe QuickContentAdderLocation -> Maybe Content -> List Content -> Html Msg
viewSeparatorForQuickContentAdder model content whichHrLine maybeQuickContentAdderLocation maybeContentOfCurrentlyOpenQuickContentEditBox contentsOfCurrentTextPart =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just _ ->
            text ""

        Nothing ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentWhichCursorIsOnItNow ->
                    --wait to get contentLineHeight info to decide to show (or not show) quickContentAdderSeparator. if contentLiteHeight value is 0, it is not gotten yet
                    if contentWhichCursorIsOnItNow.contentLineHeight == 0 then
                        text ""

                    else if
                        (contentWhichCursorIsOnItNow.contentId == content.contentId)
                            && (contentWhichCursorIsOnItNow.tagId == content.tagIdOfCurrentTextPart)
                    then
                        if contentWhichCursorIsOnItNow.offsetPosY < topOffsetForContentLine contentWhichCursorIsOnItNow.contentLineHeight && whichHrLine == Top then
                            let
                                showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator =
                                    case maybeQuickContentAdderLocation of
                                        Nothing ->
                                            True

                                        Just quickContentAdderLocation ->
                                            case quickContentAdderLocation.nextLineContentId of
                                                Nothing ->
                                                    True

                                                Just nextLineContentIdOfOpenQuickContentAdderBox ->
                                                    if nextLineContentIdOfOpenQuickContentAdderBox == content.contentId && quickContentAdderLocation.contentLineTagId == content.tagIdOfCurrentTextPart then
                                                        if quickContentAdderLocation.locatedAt == AfterContentLine then
                                                            False

                                                        else
                                                            True

                                                    else
                                                        True

                                --showOnlyIfThisIsntOneOfTheSeparatorsOfOpenQuickContentEditBox and showOnlyIfThisIsntOneOfTheSeparatorsOfThatIsAroundOfOpenQuickContentEditBox fns (actually, bool values) are completely identical with the other definitions of them that can seen on the "else" branch of this code part. I just kept them duplicated like that to not waste time by unnecessary generalization
                                showOnlyIfThisIsntOneOfTheSeparatorsOfOpenQuickContentEditBox =
                                    case maybeContentOfCurrentlyOpenQuickContentEditBox of
                                        Nothing ->
                                            True

                                        Just contentOfCurrentlyOpenQuickContentEditBox ->
                                            if contentOfCurrentlyOpenQuickContentEditBox.contentId == content.contentId && contentOfCurrentlyOpenQuickContentEditBox.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                                                False

                                            else
                                                True

                                showOnlyIfThisIsntOneOfTheSeparatorsOfThatIsAroundOfOpenQuickContentEditBox =
                                    case maybeContentOfCurrentlyOpenQuickContentEditBox of
                                        Nothing ->
                                            True

                                        Just contentOfCurrentlyOpenQuickContentEditBox ->
                                            let
                                                indexOfContentOnItsTagTextPart : Int
                                                indexOfContentOnItsTagTextPart =
                                                    Maybe.withDefault -1 (List.Extra.elemIndex contentOfCurrentlyOpenQuickContentEditBox contentsOfCurrentTextPart)

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

                                                prevOrNextContentId =
                                                    if whichHrLine == Down then
                                                        prevLineContentId

                                                    else
                                                        nextLineContentId
                                            in
                                            case prevOrNextContentId of
                                                Nothing ->
                                                    True

                                                Just prevOrNextLineContentIdOfOpenQuickContentEditBox ->
                                                    if prevOrNextLineContentIdOfOpenQuickContentEditBox == content.contentId && contentOfCurrentlyOpenQuickContentEditBox.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                                                        False

                                                    else
                                                        True
                            in
                            if
                                showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator
                                    && showOnlyIfThisIsntOneOfTheSeparatorsOfOpenQuickContentEditBox
                                    && showOnlyIfThisIsntOneOfTheSeparatorsOfThatIsAroundOfOpenQuickContentEditBox
                            then
                                div [ class "separatorForQuickContentAdderDiv" ] [ hr [] [] ]

                            else
                                text ""

                        else if contentWhichCursorIsOnItNow.offsetPosY > downOffsetForContentLine contentWhichCursorIsOnItNow.contentLineHeight && whichHrLine == Down then
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

                                showOnlyIfThisIsntOneOfTheSeparatorsOfOpenQuickContentEditBox =
                                    case maybeContentOfCurrentlyOpenQuickContentEditBox of
                                        Nothing ->
                                            True

                                        Just contentOfCurrentlyOpenQuickContentEditBox ->
                                            if contentOfCurrentlyOpenQuickContentEditBox.contentId == content.contentId && contentOfCurrentlyOpenQuickContentEditBox.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                                                False

                                            else
                                                True

                                showOnlyIfThisIsntOneOfTheSeparatorsOfThatIsAroundOfOpenQuickContentEditBox =
                                    case maybeContentOfCurrentlyOpenQuickContentEditBox of
                                        Nothing ->
                                            True

                                        Just contentOfCurrentlyOpenQuickContentEditBox ->
                                            let
                                                indexOfContentOnItsTagTextPart : Int
                                                indexOfContentOnItsTagTextPart =
                                                    Maybe.withDefault -1 (List.Extra.elemIndex contentOfCurrentlyOpenQuickContentEditBox contentsOfCurrentTextPart)

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

                                                prevOrNextContentId =
                                                    if whichHrLine == Down then
                                                        prevLineContentId

                                                    else
                                                        nextLineContentId
                                            in
                                            case prevOrNextContentId of
                                                Nothing ->
                                                    True

                                                Just prevOrNextLineContentIdOfOpenQuickContentEditBox ->
                                                    if prevOrNextLineContentIdOfOpenQuickContentEditBox == content.contentId && contentOfCurrentlyOpenQuickContentEditBox.tagIdOfCurrentTextPart == content.tagIdOfCurrentTextPart then
                                                        False

                                                    else
                                                        True
                            in
                            if
                                showOnlyIfQuickContentAdderIsNotOnAroundThisSeparator
                                    && showOnlyIfThisIsntOneOfTheSeparatorsOfOpenQuickContentEditBox
                                    && showOnlyIfThisIsntOneOfTheSeparatorsOfThatIsAroundOfOpenQuickContentEditBox
                            then
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
    textarea [ id "quickContentAdder", placeholder "add new content...", value inputText, spellcheck False, onInput QuickContentAdderInputChanged, onKeyDown (KeyDown QuickContentAdderInput), rows (calculateRowForContentAdderInput inputText), cols (calculateColForContentAdderInput inputText) ] []


calculateRowForContentAdderInput : String -> Int
calculateRowForContentAdderInput inputText =
    let
        row =
            (toFloat (recalculatedTextLengthBasedOnNewLineCounts inputText) / 70) |> ceiling
    in
    if row == 0 then
        1

    else
        row


calculateColForContentAdderInput : String -> Int
calculateColForContentAdderInput inputText =
    if recalculatedTextLengthBasedOnNewLineCounts inputText + 5 < 25 then
        25

    else
        recalculatedTextLengthBasedOnNewLineCounts inputText + 5


viewQuickContentEditInput : String -> Html Msg
viewQuickContentEditInput inputText =
    textarea [ id "quickEditBox", placeholder "", value inputText, spellcheck False, onInput QuickContentEditInputChanged, onKeyDown (KeyDown QuickContentEditInput), rows (calculateRowForContentEditInput inputText), cols (calculateColForContentEditInput inputText) ] []


calculateRowForContentEditInput : String -> Int
calculateRowForContentEditInput inputText =
    let
        row =
            (toFloat (recalculatedTextLengthBasedOnNewLineCounts inputText) / 70) |> ceiling
    in
    if row == 0 then
        1

    else
        row


calculateColForContentEditInput : String -> Int
calculateColForContentEditInput inputText =
    recalculatedTextLengthBasedOnNewLineCounts inputText + 5


recalculatedTextLengthBasedOnNewLineCounts : String -> Int
recalculatedTextLengthBasedOnNewLineCounts text =
    String.length text + ((List.length (String.split "\n" text) - 1) * 70)


viewDragDropSeparator : Model -> Content -> TagTextPart -> WhichHrLine -> Html Msg
viewDragDropSeparator model content currentTagTextPart whichHrLine =
    case model.contentTagIdDuoThatIsBeingDragged of
        Just beingDraggedContent ->
            case model.contentTagDuoWhichCursorIsOverItNow of
                Just contentWhichCursorIsOnItNow ->
                    if
                        (contentWhichCursorIsOnItNow.contentId == content.contentId)
                            && (contentWhichCursorIsOnItNow.tagId == content.tagIdOfCurrentTextPart)
                            && contentWhichCursorIsOnItNowIsNotSameWithDraggedContent beingDraggedContent contentWhichCursorIsOnItNow
                            && (ifActiveViewTypeIsLineView model || currentTextPartDoesNotHaveSameContentWithBeingDraggedContent beingDraggedContent currentTagTextPart)
                            && beingDraggedContentIsNotAtNear whichHrLine currentTagTextPart beingDraggedContent contentWhichCursorIsOnItNow
                    then
                        if contentWhichCursorIsOnItNow.offsetPosY < topOffsetForContentLine contentWhichCursorIsOnItNow.contentLineHeight && whichHrLine == Top then
                            div [ class "dragDropSeparatorDiv" ] [ hr [] [] ]

                        else if contentWhichCursorIsOnItNow.offsetPosY > downOffsetForContentLine contentWhichCursorIsOnItNow.contentLineHeight && whichHrLine == Down then
                            div [ class "dragDropSeparatorDiv" ] [ hr [] [] ]

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
                            if c.offsetPosY < topOffsetForContentLine c.contentLineHeight || c.offsetPosY > downOffsetForContentLine c.contentLineHeight then
                                let
                                    locateAt =
                                        if c.offsetPosY < topOffsetForContentLine c.contentLineHeight then
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

                            else if contentHasLinkInside content.text then
                                SetContentTagIdDuoToDragAfterASecond (Just (ContentTagIdDuo content.contentId content.tagIdOfCurrentTextPart))

                            else
                                SetContentTagIdDuoToDrag (Just (ContentTagIdDuo content.contentId content.tagIdOfCurrentTextPart))

                        Nothing ->
                            DoNothing

                _ ->
                    SetContentTagIdDuoToDrag Nothing
        )


onRightClick : Content -> Attribute Msg
onRightClick content =
    Mouse.onDoubleClick
        (\_ ->
            OpenQuickContentEditInput content
        )


onMouseOver : Model -> Content -> Attribute Msg
onMouseOver model content =
    Mouse.onMove
        (\event ->
            SetContentWhichCursorIsOverIt
                (Just
                    (ContentTagIdDuoWithOffsetPosY content.contentId
                        content.tagIdOfCurrentTextPart
                        (second event.offsetPos)
                        (case model.contentTagDuoWhichCursorIsOverItNow of
                            Nothing ->
                                0

                            Just c ->
                                c.contentLineHeight
                        )
                    )
                )
        )


onMouseLeave : Attribute Msg
onMouseLeave =
    Mouse.onLeave
        (\_ ->
            SetContentWhichCursorIsOverIt Nothing
        )
