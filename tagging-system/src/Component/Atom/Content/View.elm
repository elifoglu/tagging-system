module Content.View exposing (viewContentDiv)

import App.Model exposing (MaybeContentFadeOutData, MaybeTextToHighlight)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content, GotGraphData)
import Content.Util exposing (maybeDateText, maybeTagsOfContent)
import DataResponse exposing (ContentID)
import ForceDirectedGraphForContent exposing (viewGraphForContent)
import Html exposing (Html, a, div, img, p, span, text)
import Html.Attributes exposing (class, href, src, style, title)
import Markdown exposing (defaultOptions)
import Tag.Model exposing (Tag)


viewContentDiv : MaybeContentFadeOutData -> MaybeTextToHighlight -> Content -> Html Msg
viewContentDiv dataToFadeContent textToHighlight content =
    case content.graphDataIfGraphIsOn of
        Nothing ->
            viewContentDivWithoutGraph dataToFadeContent textToHighlight content

        Just graphData ->
            if List.isEmpty graphData.graphData.contentIds then
                viewContentDivWithoutGraph dataToFadeContent textToHighlight content

            else if graphData.veryFirstMomentOfGraphHasPassed then
                div []
                    [ div [ class "graphForContent" ] [ viewGraphForContent content.contentId graphData.graphData.contentIds graphData.graphModel graphData.contentToColorize ]
                    , viewContentDivWithoutGraph dataToFadeContent textToHighlight content
                    ]

            else
                text ""


viewContentDivWithoutGraph : MaybeContentFadeOutData -> MaybeTextToHighlight -> Content -> Html Msg
viewContentDivWithoutGraph dataToFadeContent textToHighlight content =
    p [ style "opacity" (getOpacityLevel content.contentId dataToFadeContent) ]
        [ div []
            [ div [ class "title" ] [ viewContentTitle content.title ]
            , viewRefsTextOfContent content
            , viewMarkdownTextOfContent content textToHighlight
            , viewFurtherReadingRefsTextOfContent content
            ]
        , viewContentInfoDiv content
        ]


getOpacityLevel : ContentID -> MaybeContentFadeOutData -> String
getOpacityLevel contentId maybeContentFadeData =
    case maybeContentFadeData of
        Just data ->
            if contentId == data.contentIdToFade then
                String.fromFloat data.opacityLevel

            else
                "1"

        Nothing ->
            "1"


viewContentTitle : Maybe String -> Html Msg
viewContentTitle maybeTitle =
    case maybeTitle of
        Just title ->
            text (title ++ " ")

        Nothing ->
            text ""


viewContentInfoDiv : Content -> Html Msg
viewContentInfoDiv content =
    div [ class "contentInfoDiv" ]
        ((case ( maybeTagsOfContent content, maybeDateText content ) of
            ( Just displayableTagsOfContent, Just dateText ) ->
                viewTagLinks displayableTagsOfContent
                    ++ [ text (", " ++ dateText) ]

            ( _, _ ) ->
                []
         )
            ++ [ text " ", viewContentLinkWithLinkIcon content, viewGraphLink content ]
        )


viewTagLinks : List Tag -> List (Html Msg)
viewTagLinks tags =
    tags
        |> List.map viewTagLink
        |> List.intersperse (text " ")


viewTagLink : Tag -> Html Msg
viewTagLink tag =
    a [ href ("/tags/" ++ tag.tagId), class "tagLink" ] [ text ("#" ++ tag.name) ]


viewContentLink : Html msg -> String -> Html msg
viewContentLink htmlToClick contentId =
    a [ href ("/contents/" ++ contentId) ]
        [ htmlToClick
        ]


viewContentLinkWithLinkIcon : Content -> Html msg
viewContentLinkWithLinkIcon content =
    viewContentLink (img [ class "navToContent", src "/link.svg" ] []) (String.fromInt content.contentId)


viewGraphLink : Content -> Html Msg
viewGraphLink content =
    if List.isEmpty content.gotGraphData.connections then
        text ""

    else
        case content.graphDataIfGraphIsOn of
            Just _ ->
                a [ href ("/contents/" ++ String.fromInt content.contentId) ]
                    [ img [ class "contentPageToggleChecked", src "/graph.svg" ] [] ]

            Nothing ->
                a [ href ("/contents/" ++ String.fromInt content.contentId ++ "?graph=true") ]
                    [ img [ class "contentPageToggleChecked", src "/graph.svg" ] [] ]


viewMarkdownTextOfContent : Content -> MaybeTextToHighlight -> Html msg
viewMarkdownTextOfContent content maybeTextToHighlight =
    Markdown.toHtmlWith { defaultOptions | sanitize = False }
        [ class "markdownDiv contentFont" ]
        (case maybeTextToHighlight of
            Just textToHighlight ->
                -- Note: This highlighting feature is unfortunately case sensitive for now
                String.replace textToHighlight ("<span class=textToHighlight>" ++ textToHighlight ++ "</span>") content.text

            Nothing ->
                content.text
        )


viewRefsTextOfContent : Content -> Html msg
viewRefsTextOfContent content =
    if List.isEmpty content.refs then
        text ""

    else
        div [ class "refsDiv" ]
            [ span [ style "font-style" "italic" ] [ text "ilgili: " ]
            , span []
                (content.refs
                    |> List.map (\r -> viewContentLink (text r.text) r.id)
                    |> List.intersperse (text ", ")
                )
            ]


viewFurtherReadingRefsTextOfContent : Content -> Html msg
viewFurtherReadingRefsTextOfContent content =
    if List.isEmpty content.furtherReadingRefs then
        text ""

    else
        div [ class "refsDiv", style "margin-top" "25px", style "margin-bottom" "14px" ]
            [ span [ style "font-style" "italic" ] [ text "ileri okuma: " ]
            , span []
                (content.furtherReadingRefs
                    |> List.map (\r -> viewContentLink (text r.text) r.id)
                    |> List.intersperse (text ", ")
                )
            ]
