module Content.View exposing (viewContentDiv)

import App.Model exposing (MaybeTextToHighlight)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import Content.Util exposing (maybeDateText, maybeTagsOfContent)
import Html exposing (Html, a, div, img, p, text)
import Html.Attributes exposing (class, href, src, title)
import Markdown exposing (defaultOptions)
import Tag.Model exposing (Tag)


viewContentDiv : MaybeTextToHighlight -> Content -> Html Msg
viewContentDiv textToHighlight content =
    p []
        [ div []
            [ div [ class "title" ] [ viewContentTitle content.title ]
            , viewMarkdownTextOfContent content textToHighlight
            ]
        , viewContentInfoDiv content
        ]


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
            ++ [ text " ", viewContentLinkWithLinkIcon content ]
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
