module ContentPage.View exposing (viewContentPageDiv)

import App.Model exposing (InitializedContentPageModel)
import App.Msg exposing (KeyDownPlace(..), Msg(..))
import Component.ContentTextUtil exposing (createBeautifiedContentText)
import Content.Model exposing (Content)
import Content.Util exposing (createdDateOf, lastModifiedDateOf)
import Html exposing (Html, a, br, div, p, text)
import Html.Attributes exposing (class, href)
import Tag.Model exposing (Tag)


viewContentPageDiv : InitializedContentPageModel -> Html Msg
viewContentPageDiv contentPageModel =
    div [ class "contentPageDiv"]
        [ viewContentDiv contentPageModel.content
        ]


viewContentDiv : Content -> Html Msg
viewContentDiv content =
    p []
        [ div []
            [ div [ class "contentTitleOnContentPage" ] [ viewContentTitle content.title ]
            , viewTextOfContent content
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
    div [ class "contentInfoDivOnContentPage" ]
        (viewTagLinks content.tags
            ++ [ if List.length content.tags > 0 then
                    br [] []

                 else
                    text ""
               ]
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
    a [ href ("/tags/" ++ tag.tagId), class "tagLinkOnSearchPage" ] [ text ("#" ++ tag.name) ]


viewTextOfContent : Content ->  Html msg
viewTextOfContent content =
    div [ class "contentInSearchPage" ] [ createBeautifiedContentText content.text ]
