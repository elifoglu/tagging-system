module App.View exposing (view)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Breadcrumb.View exposing (viewBreadcrumb)
import Browser exposing (Document)
import Content.View exposing (viewContentDiv)
import ContentSearch.View exposing (viewSearchContentDiv)
import CreateContent.View exposing (viewCreateContentDiv)
import CreateTag.View exposing (viewCreateTagDiv)
import ForceDirectedGraphForGraph exposing (viewGraphForGraphPage)
import ForceDirectedGraphForTag exposing (viewGraph)
import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown
import NotFound.View exposing (view404Div)
import Tag.View exposing (viewTagPageDiv)
import UpdateContent.View exposing (viewUpdateContentDiv)
import UpdateTag.View exposing (viewUpdateTagDiv)


view : Model -> Document Msg
view model =
    { title = "tagging system"
    , body =
        [ div []
            [ div [ class "header" ] <| viewBreadcrumb model
            , div [ class "body" ]
                (case model.activePage of
                    TagPage status ->
                        case status of
                            NonInitialized _ ->
                                []

                            Initialized initialized ->
                                case initialized.maybeGraphData of
                                    Just graphData ->
                                        if graphData.veryFirstMomentOfGraphHasPassed then
                                            [ div [ class "graphForTagPage", style "margin-top" "50px" ] [ viewGraph graphData.graphData.contentIds graphData.graphModel 0 graphData.contentToColorize ]
                                            , viewTagPageDiv initialized model.allTags
                                            ]

                                        else
                                            []

                                    Nothing ->
                                        []

                    ContentPage status ->
                        case status of
                            NonInitialized _ ->
                                []

                            Initialized content ->
                                [ viewContentDiv Nothing content
                                , a [ href ("/update/content/" ++ String.fromInt content.contentId), class "updateContentLink" ] [ text "(update this content)" ]
                                ]

                    CreateContentPage status ->
                        case status of
                            NoRequestSentYet createContentPageModel ->
                                [ viewCreateContentDiv createContentPageModel ]

                            RequestSent _ ->
                                [ text "..." ]

                    UpdateContentPage updateContentPageModel ->
                        case updateContentPageModel of
                            GotContentToUpdate updateContentPageData ->
                                [ viewUpdateContentDiv updateContentPageData updateContentPageData.maybeContentToPreview updateContentPageData.contentId ]

                            _ ->
                                [ text "..." ]

                    CreateTagPage status ->
                        case status of
                            NoRequestSentYet createTagPageModel ->
                                [ viewCreateTagDiv model createTagPageModel ]

                            RequestSent _ ->
                                [ text "..." ]

                    UpdateTagPage status ->
                        case status of
                            NoRequestSentYet ( updateTagPageModel, tagId ) ->
                                [ viewUpdateTagDiv updateTagPageModel tagId ]

                            RequestSent _ ->
                                [ text "..." ]

                    ContentSearchPage searchKeyword contents ->
                        [ viewSearchContentDiv searchKeyword contents ]

                    GraphPage maybeGraphData ->
                        case maybeGraphData of
                            Just graphData ->
                                if graphData.veryFirstMomentOfGraphHasPassed then
                                    [ div [ class "graphForGraphPage", style "margin-top" "5px" ] [ viewGraphForGraphPage graphData.graphData.contentIds graphData.graphModel graphData.contentToColorize ]
                                    , Markdown.toHtml [ class "graphPageInformationText" ] ("*(imleç nodun üzerinde bekletilerek ilgili içerik hakkında bilgi sahibi olunabilir," ++ "  \n" ++ "sol tık ile ilgili içeriğe gidilebilir (ctrl + sol tık yeni sekmede açar)," ++ "  \n" ++ "sağ tık ile nod sürüklenerek eğlenilebilir)*")
                                    ]

                                else
                                    []

                            Nothing ->
                                []

                    NotFoundPage ->
                        [ view404Div ]

                    MaintenancePage ->
                        [ text "*bakım çalışması*" ]
                )
            ]
        ]
    }
