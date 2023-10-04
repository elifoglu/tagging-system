module Content.View exposing (viewContentDiv, viewContentInfoDiv)

import App.Model exposing (MaybeTextToHighlight)
import App.Msg exposing (Msg(..))
import Content.Model exposing (Content)
import Content.Util exposing (createdDateOf, lastModifiedDateOf)
import Html exposing (Html, a, br, div, img, p, text)
import Html.Attributes exposing (class, href, src, title)
import Html.Parser
import Html.Parser.Util
import Tag.Model exposing (Tag)


viewContentDiv : MaybeTextToHighlight -> Content -> Html Msg
viewContentDiv textToHighlight content =
    p []
        [ div []
            [ div [ class "contentTitleOnSearchContentPage" ] [ viewContentTitle content.title ]
            , viewTextOfContent content textToHighlight
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
    div [ class "contentInfoDivOnSearchPage" ]
        (viewTagLinks content.tags
            ++ [ if List.length content.tags > 0 then br [] [] else text ""]
            ++ [ text ("created at: " ++ createdDateOf content) ]
            ++ [ text (", modified at: " ++ lastModifiedDateOf content) ]
        )


viewTagLinks : List Tag -> List (Html Msg)
viewTagLinks tags =
    tags
        |> List.map viewTagLink
        |> List.intersperse (text ", ")


viewTagLink : Tag -> Html Msg
viewTagLink tag =
    a [ href ("/tags/" ++ tag.tagId), class "tagLink" ] [ text ("#" ++ tag.name) ]

viewTextOfContent : Content -> MaybeTextToHighlight -> Html msg
viewTextOfContent content maybeTextToHighlight =
    let
        htmlText : String
        htmlText =
            case maybeTextToHighlight of
                Just textToHighlight ->
                    -- Note: This highlighting feature is unfortunately case sensitive for now
                    String.replace textToHighlight ("<span class=textToHighlight>" ++ textToHighlight ++ "</span>") content.text

                Nothing ->
                    content.text

        nodes =
            case Html.Parser.run htmlText of
                Ok parsedNodes ->
                    Html.Parser.Util.toVirtualDom parsedNodes

                Err _ ->
                    []
    in
    div [ class "contentTextDiv contentFont" ] nodes
