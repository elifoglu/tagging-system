module Component.ContentTextUtil exposing (createBeautifiedContentText, contentHasLinkInside)

import Html exposing (Attribute, Html, span)
import Html.Attributes exposing (class)
import Markdown exposing (defaultOptions)


createBeautifiedContentText : String -> Html msg
createBeautifiedContentText contentText =
    let
        beautified =
            contentText
                |> makeNewLineIdentifiersSuitableForMarkdown
                |> updateContentTextWithClickableLinks
    in
    span [] [Markdown.toHtml [ class "contentLineMarkdown" ] beautified]

updateContentTextWithClickableLinks : String -> String
updateContentTextWithClickableLinks contentText =
    let
        wrapLinkWordWithA : String -> String
        wrapLinkWordWithA link =
            "[link](" ++ link ++ ")"

        textWithAddedATagsToLinks =
            String.split " " contentText
                |> List.map
                    (\word ->
                        if wordIsARawLink word then
                            wrapLinkWordWithA word

                        else
                            word
                    )
                |> String.join " "
    in
    textWithAddedATagsToLinks


makeNewLineIdentifiersSuitableForMarkdown : String -> String
makeNewLineIdentifiersSuitableForMarkdown contentText =
    String.replace "\n" "&nbsp;  \n" contentText


wordIsARawLink : String -> Bool
wordIsARawLink word =
    List.any (\httpPrefix -> String.startsWith httpPrefix word) [ "http://", "https://" ]


wordIsAMarkdownLink : String -> Bool
wordIsAMarkdownLink word =
    String.startsWith "[" word && String.contains "](" word  && String.endsWith ")" word


contentHasLinkInside : String -> Bool
contentHasLinkInside contentText =
    String.split " " contentText
        |> List.map (\word -> wordIsARawLink word || wordIsAMarkdownLink word)
        |> List.any (\isALink -> isALink == True)