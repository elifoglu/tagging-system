module BioGroup.View exposing (viewBioGroup, viewBioGroupInfoDiv)

import App.Msg exposing (Msg(..))
import BioGroup.Model exposing (BioGroup)
import Html exposing (Html, button, div, img, p, span, text)
import Html.Attributes exposing (class, src, style)
import Html.Events exposing (onClick)
import Markdown


viewBioGroup : BioGroup -> Html Msg
viewBioGroup bioGroup =
    span []
        [ if String.startsWith "/" bioGroup.title then
            if bioGroup.url == "home" && bioGroup.isActive then
                text ""

            else
                img [ class (decideBioGroupClass bioGroup), src bioGroup.title, onClick (ClickOnABioGroup bioGroup.url) ] []

          else
            button [ class (decideBioGroupClass bioGroup), onClick (ClickOnABioGroup bioGroup.url) ]
                [ text bioGroup.title ]
        , case bioGroup.info of
            Just _ ->
                if String.startsWith "/" bioGroup.title then
                    text ""

                else
                    span [ style "font-size" "12px" ]
                        [ img [ onClick (BioGroupDisplayInfoChanged bioGroup), class "openBioGroupInfo", src (getProperInfoIcon bioGroup) ] []
                        ]

            Nothing ->
                text ""
        ]


getProperInfoIcon : BioGroup -> String
getProperInfoIcon bioGroup =
    if bioGroup.isActive && bioGroup.displayInfo then
        "/info.svg"

    else
        "/info-gray.svg"


decideBioGroupClass : BioGroup -> String
decideBioGroupClass bioGroup =
    if bioGroup.isActive then
        if String.startsWith "/" bioGroup.title then
            "bioGroup-iconish bioGroup-iconish-active"

        else
            "bioGroup bioGroup-active"

    else if String.startsWith "/" bioGroup.title then
        "bioGroup-iconish"

    else
        "bioGroup"


viewBioGroupInfoDiv : BioGroup -> Html Msg
viewBioGroupInfoDiv bioGroup =
    case bioGroup.info of
        Just info ->
            if bioGroup.displayInfo then
                div [ class "bioGroupInfoContainer" ]
                    [ p [ class "bioGroupInfoP" ]
                        [ Markdown.toHtml [ class "markdownDiv" ] info
                        ]
                    ]

            else
                text ""

        Nothing ->
            div [] []
