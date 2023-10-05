module Component.ContentTextUtil exposing (createBeautifiedContentText, contentHasLinkInside)

import Html exposing (Attribute, Html, span)
import Html.Parser
import Html.Parser.Util


createBeautifiedContentText : String -> Html msg
createBeautifiedContentText contentText =
    let
        beautified =
            contentText
                |> replaceNewLineIdentifiersWithBrTags
                |> updateContentTextWithClickableLinks
    in
    span []
        (case Html.Parser.run beautified of
            Ok parsedNodes ->
                Html.Parser.Util.toVirtualDom parsedNodes

            Err _ ->
                []
        )

updateContentTextWithClickableLinks : String -> String
updateContentTextWithClickableLinks contentText =
    let
        wrapLinkWordWithA : String -> String
        wrapLinkWordWithA link =
            "<a class=\"contentLineA\" href=\"" ++ link ++ "\">link</a>"

        textWithAddedATagsToLinks =
            String.split " " contentText
                |> List.map
                    (\word ->
                        if wordIsALink word then
                            wrapLinkWordWithA word

                        else
                            word
                    )
                |> String.join " "
    in
    textWithAddedATagsToLinks


replaceNewLineIdentifiersWithBrTags : String -> String
replaceNewLineIdentifiersWithBrTags contentText =
    String.replace "\n" " <br> " contentText


wordIsALink : String -> Bool
wordIsALink word =
    List.any (\httpPrefix -> String.contains httpPrefix word) [ "http://", "https://" ]


contentHasLinkInside : String -> Bool
contentHasLinkInside contentText =
    String.split " " contentText
        |> List.map (\word -> wordIsALink word)
        |> List.any (\isALink -> isALink == True)