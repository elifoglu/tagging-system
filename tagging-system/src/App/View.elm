module App.View exposing (view)

import App.Model exposing (..)
import App.Msg exposing (Msg(..))
import Breadcrumb.View exposing (viewBreadcrumb)
import Browser exposing (Document)
import Content.View exposing (viewContentDiv)
import ContentSearch.View exposing (viewSearchContentDiv)
import Contents.View exposing (viewContentDivs)
import CreateContent.View exposing (viewCreateContentDiv)
import CreateTag.View exposing (viewCreateTagDiv)
import ForceDirectedGraphForGraph exposing (viewGraphForGraphPage)
import ForceDirectedGraphForHome exposing (viewGraph)
import Home.View exposing (tagCountCurrentlyShownOnPage, viewHomePageDiv)
import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown
import NotFound.View exposing (view404Div)
import Pagination.View exposing (viewPagination)
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
                    HomePage allTagsToShow maybeGraphData ->
                            case maybeGraphData of
                                Just graphData ->
                                    if graphData.veryFirstMomentOfGraphHasPassed then
                                        let
                                            tagsCount =
                                                tagCountCurrentlyShownOnPage allTagsToShow

                                            initialMarginTop =
                                                50

                                            heightOfASingleTagAsPx =
                                                20

                                            marginTopForGraph : Int
                                            marginTopForGraph =
                                                initialMarginTop + round (toFloat tagsCount * heightOfASingleTagAsPx)
                                        in
                                        [ viewHomePageDiv allTagsToShow
                                        , div [ class "graph", style "margin-top" (String.fromInt marginTopForGraph ++ "px") ] [ viewGraph graphData.graphData.contentIds graphData.graphModel tagsCount graphData.contentToColorize ]
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
                                [ viewContentDiv Nothing Nothing content
                                , a [ href ("/update/content/" ++ String.fromInt content.contentId), class "updateContentLink" ] [ text "(update this content)" ]
                                ]

                    TagPage status ->
                        case status of
                            NonInitialized _ ->
                                []

                            Initialized initialized ->
                                viewContentDivs model.maybeContentFadeOutData initialized.contents
                                    ++ [ viewPagination initialized.tag initialized.pagination
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

                    RedirectPage _ ->
                        [ text "..." ]

                    NotFoundPage ->
                        [ view404Div ]

                    MaintenancePage ->
                        [ text "*bakım çalışması*" ]

                )
            ]
        ]
    }
