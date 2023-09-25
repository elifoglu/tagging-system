module Main exposing (main, needAllTagsData)

import App.Model exposing (..)
import App.Msg exposing (ContentInputType(..), Msg(..), TagInputType(..))
import App.Ports exposing (openNewTab, sendTitle)
import App.UrlParser exposing (pageBy)
import App.View exposing (view)
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Component.Page.Util exposing (tagsNotLoaded)
import Content.Model exposing (Content, GraphData)
import Content.Util exposing (gotContentToContent)
import DataResponse exposing (ContentID, EksiKonserveException)
import ForceDirectedGraphForContent exposing (graphSubscriptionsForContent, initGraphModelForContent)
import ForceDirectedGraphForGraph exposing (graphSubscriptionsForGraph, initGraphModelForGraphPage)
import ForceDirectedGraphForHome exposing (graphSubscriptions, initGraphModel)
import ForceDirectedGraphUtil exposing (updateGraph)
import Home.View exposing (tagCountCurrentlyShownOnPage)
import List
import Pagination.Model exposing (Pagination)
import Requests exposing (createNewTag, getAllTagsResponse, getContent, getHomePageDataResponse, getSearchResult, getTagContents, getTimeZone, getUrlToRedirect, getWholeGraphData, postNewContent, previewContent, updateExistingContent, updateExistingTag)
import Tag.Util exposing (tagById)
import Task
import Time
import Url


main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : {} -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        page =
            pageBy url

        model =
            Model "log" key [] page LocalStorage False Time.utc
    in
    ( model
    , Cmd.batch [ getCmdToSendByPage model, getTimeZone ]
    )


needAllTagsData : Page -> Bool
needAllTagsData page =
    case page of
        ContentPage _ ->
            True

        TagPage _ ->
            True

        UpdateContentPage _ ->
            True

        ContentSearchPage _ _ ->
            True

        HomePage _ _ ->
            False

        CreateContentPage _ ->
            False

        CreateTagPage _ ->
            False

        UpdateTagPage _ ->
            False

        GraphPage _ ->
            False

        RedirectPage _ ->
            False

        NotFoundPage ->
            False

        MaintenancePage ->
            False


getCmdToSendByPage : Model -> Cmd Msg
getCmdToSendByPage model =
    Cmd.batch
        [ sendTitle model
        , if tagsNotLoaded model && needAllTagsData model.activePage then
            getAllTagsResponse

          else
            case model.activePage of
                HomePage allTagsToShow maybeGraphData ->
                    if allTagsToShow == Nothing then
                        getHomePageDataResponse

                    else if maybeGraphData == Nothing then
                        getWholeGraphData

                    else
                        Cmd.none

                TagPage status ->
                    case status of
                        NonInitialized initializableTagPageModel ->
                            case tagById model.allTags initializableTagPageModel.tagId of
                                Just tag ->
                                    getTagContents tag initializableTagPageModel.maybePage

                                Nothing ->
                                    Cmd.none

                        Initialized _ ->
                            Cmd.none

                ContentPage status ->
                    case status of
                        NonInitialized ( contentId, _ ) ->
                            getContent contentId model

                        Initialized _ ->
                            Cmd.none

                UpdateContentPage status ->
                    case status of
                        NotInitializedYet contentID ->
                            getContent contentID model

                        _ ->
                            Cmd.none

                GraphPage maybeGraphData ->
                    case maybeGraphData of
                        Just _ ->
                            Cmd.none

                        Nothing ->
                            getWholeGraphData

                RedirectPage path ->
                    getUrlToRedirect path

                _ ->
                    Cmd.none
        ]


createNewModelAndCmdMsg : Model -> Page -> ( Model, Cmd Msg )
createNewModelAndCmdMsg model page =
    let
        newModel =
            { model | activePage = page }
    in
    ( newModel, getCmdToSendByPage newModel )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- COMMON --
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                activePage : Page
                activePage =
                    pageBy url

                newModel : Model
                newModel =
                    { model | allTags = [], activePage = activePage }
            in
            ( newModel, getCmdToSendByPage newModel )

        GotTimeZone zone ->
            ( { model | timeZone = zone }, Cmd.none )

        GotAllTagsResponse res ->
            case res of
                Ok gotTagDataResponse ->
                    let
                        newModel =
                            { model | allTags = gotTagDataResponse.allTags }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        GotContent result ->
            case result of
                Ok gotContent ->
                    let
                        content =
                            gotContentToContent model gotContent

                        contentPage =
                            ContentPage <| Initialized content

                        newActivePage =
                            case model.activePage of
                                ContentPage (NonInitialized ( _, graphIsOn )) ->
                                    let
                                        newContent =
                                            if not graphIsOn then
                                                content

                                            else
                                                { content | graphDataIfGraphIsOn = Just (GraphData content.gotGraphData (initGraphModelForContent content.gotGraphData) False Nothing) }

                                        newContentPage =
                                            ContentPage <| Initialized newContent
                                    in
                                    newContentPage

                                CreateContentPage status ->
                                    case status of
                                        NoRequestSentYet _ ->
                                            CreateContentPage <|
                                                NoRequestSentYet (setCreateContentPageModel content)

                                        RequestSent _ ->
                                            contentPage

                                UpdateContentPage status ->
                                    case status of
                                        NotInitializedYet _ ->
                                            UpdateContentPage <|
                                                GotContentToUpdate (setUpdateContentPageModel content)

                                        GotContentToUpdate _ ->
                                            UpdateContentPage <|
                                                GotContentToUpdate (setUpdateContentPageModel content)

                                        UpdateRequestIsSent _ ->
                                            contentPage

                                _ ->
                                    MaintenancePage

                        newModel =
                            { model | activePage = newActivePage }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- TAG PAGE --
        GotContentsOfTag tag result ->
            case result of
                Ok contentsResponse ->
                    case model.activePage of
                        TagPage status ->
                            case status of
                                NonInitialized nonInitialized ->
                                    let
                                        currentPage =
                                            Maybe.withDefault 1 nonInitialized.maybePage

                                        pagination =
                                            Pagination currentPage contentsResponse.totalPageCount

                                        contents =
                                            List.map (gotContentToContent model) contentsResponse.contents

                                        newPage =
                                            TagPage <|
                                                Initialized (InitializedTagPageModel tag contents pagination)

                                        newModel =
                                            { model | activePage = newPage }
                                    in
                                    ( newModel, getCmdToSendByPage newModel )

                                _ ->
                                    createNewModelAndCmdMsg model NotFoundPage

                        _ ->
                            createNewModelAndCmdMsg model NotFoundPage

                Err _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        -- CREATE/UPDATE CONTENT PAGES --
        ContentInputChanged inputType input ->
            case model.activePage of
                CreateContentPage status ->
                    case status of
                        NoRequestSentYet createContentPageModel ->
                            let
                                newCurrentPageModel =
                                    case inputType of
                                        Id ->
                                            { createContentPageModel | id = input }

                                        Title ->
                                            { createContentPageModel | title = input }

                                        Text ->
                                            { createContentPageModel | text = input }

                                        Tags ->
                                            { createContentPageModel | tags = input }

                                        Refs ->
                                            { createContentPageModel | refs = input }

                                        ContentToCopy ->
                                            { createContentPageModel | contentIdToCopy = input }
                            in
                            ( { model | activePage = CreateContentPage <| NoRequestSentYet newCurrentPageModel }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                UpdateContentPage status ->
                    case status of
                        GotContentToUpdate updateContentPageData ->
                            let
                                newCurrentPageModel =
                                    case inputType of
                                        Id ->
                                            updateContentPageData

                                        Title ->
                                            { updateContentPageData | title = input }

                                        Text ->
                                            { updateContentPageData | text = input }

                                        Tags ->
                                            { updateContentPageData | tags = input }

                                        Refs ->
                                            { updateContentPageData | refs = input }

                                        ContentToCopy ->
                                            updateContentPageData
                            in
                            ( { model | activePage = UpdateContentPage <| GotContentToUpdate newCurrentPageModel }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PreviewContent previewContentModel ->
            ( model
            , previewContent previewContentModel
            )

        GetContentToCopyForContentCreation contentId ->
            ( model
            , getContent contentId model
            )

        GotContentToPreviewForCreatePage createContentPageModel result ->
            case result of
                Ok gotContentToPreview ->
                    let
                        content =
                            gotContentToContent model gotContentToPreview

                        newCreateContentPageModel =
                            { createContentPageModel | maybeContentToPreview = Just content }
                    in
                    ( { model | activePage = CreateContentPage <| NoRequestSentYet newCreateContentPageModel }
                    , Cmd.none
                    )

                Err _ ->
                    let
                        newCreateContentPageModel =
                            { createContentPageModel | maybeContentToPreview = Nothing }
                    in
                    ( { model | activePage = CreateContentPage <| NoRequestSentYet newCreateContentPageModel }
                    , Cmd.none
                    )

        CreateContent createContentPageModel ->
            ( { model | activePage = CreateContentPage <| RequestSent createContentPageModel }
            , postNewContent createContentPageModel
            )

        GotContentToPreviewForUpdatePage contentID updateContentPageData result ->
            case result of
                Ok gotContentToPreview ->
                    let
                        content =
                            gotContentToContent model gotContentToPreview

                        newUpdateContentPageModel =
                            { updateContentPageData | maybeContentToPreview = Just content }
                    in
                    ( { model | activePage = UpdateContentPage <| GotContentToUpdate newUpdateContentPageModel }
                    , Cmd.none
                    )

                Err _ ->
                    let
                        newUpdateContentPageModel =
                            { updateContentPageData | maybeContentToPreview = Nothing }
                    in
                    ( { model | activePage = UpdateContentPage <| GotContentToUpdate newUpdateContentPageModel }
                    , Cmd.none
                    )

        UpdateContent contentID updateContentPageData ->
            ( { model | activePage = UpdateContentPage <| UpdateRequestIsSent updateContentPageData }
            , updateExistingContent contentID updateContentPageData
            )

        -- CREATE/UPDATE TAG PAGES --
        TagInputChanged inputType ->
            case model.activePage of
                CreateTagPage status ->
                    case status of
                        NoRequestSentYet createTagPageModel ->
                            let
                                newCurrentPageModel =
                                    case inputType of
                                        TagId input ->
                                            { createTagPageModel | tagId = input }

                                        Name input ->
                                            { createTagPageModel | name = input }

                                        InfoContentId _ ->
                                            createTagPageModel
                            in
                            ( { model | activePage = CreateTagPage <| NoRequestSentYet newCurrentPageModel }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                UpdateTagPage status ->
                    case status of
                        NoRequestSentYet ( updateTagPageModel, tagId ) ->
                            let
                                newCurrentPageModel =
                                    case inputType of
                                        InfoContentId input ->
                                            { updateTagPageModel | infoContentId = input }

                                        _ ->
                                            updateTagPageModel
                            in
                            ( { model | activePage = UpdateTagPage <| NoRequestSentYet ( newCurrentPageModel, tagId ) }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CreateTag createTagPageModel ->
            ( { model | activePage = CreateTagPage <| RequestSent createTagPageModel }
            , createNewTag createTagPageModel
            )

        UpdateTag tagId updateTagPageModel ->
            ( { model | activePage = UpdateTagPage <| RequestSent updateTagPageModel }
            , updateExistingTag tagId updateTagPageModel
            )

        GotTagUpdateOrCreationDoneResponse res ->
            case res of
                Ok message ->
                    let
                        newActivePage =
                            if message == "done" then
                                HomePage Nothing Nothing

                            else
                                NotFoundPage

                        newModel =
                            { model | allTags = [], activePage = newActivePage }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- SEARCH PAGE --
        GotSearchInput searchKeyword ->
            let
                newPage =
                    case model.activePage of
                        HomePage _ _ ->
                            ContentSearchPage searchKeyword []

                        ContentSearchPage _ contentList ->
                            ContentSearchPage searchKeyword contentList

                        _ ->
                            model.activePage

                newModel =
                    { model | activePage = newPage }

                getAllTagsCmdMsg =
                    case model.activePage of
                        HomePage _ _ ->
                            getCmdToSendByPage newModel

                        _ ->
                            Cmd.none
            in
            ( newModel, Cmd.batch [ sendTitle newModel, getAllTagsCmdMsg, getSearchResult searchKeyword newModel, Dom.focus "contentSearchInput" |> Task.attempt FocusResult ] )

        GotContentSearchResponse res ->
            case res of
                Ok gotContentSearchResponse ->
                    let
                        newPage =
                            case model.activePage of
                                ContentSearchPage searchKeyword _ ->
                                    ContentSearchPage searchKeyword (List.map (gotContentToContent model) gotContentSearchResponse.contents)

                                _ ->
                                    model.activePage
                    in
                    ( { model | activePage = newPage }, Cmd.none )

                Err _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        -- HOME PAGE & GRAPH --
        GotHomePageDataResponse res ->
            case res of
                Ok gotTagDataResponse ->
                    case model.activePage of
                        HomePage _ maybeGraphData ->
                            let
                                homePage =
                                    HomePage (Just gotTagDataResponse.allTagsToShow) maybeGraphData

                                newModel =
                                    { model | activePage = homePage }
                            in
                            ( newModel, getCmdToSendByPage newModel )

                        _ ->
                            createNewModelAndCmdMsg model MaintenancePage

                Err _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        GotGraphData res ->
            case res of
                Ok gotGraphData ->
                    let
                        newModel =
                            case model.activePage of
                                HomePage allTags maybeGraphData ->
                                    case maybeGraphData of
                                        Just _ ->
                                            model

                                        Nothing ->
                                            { model | activePage = HomePage allTags (Just (GraphData gotGraphData (initGraphModel gotGraphData) False Nothing)) }

                                GraphPage maybeGraphData ->
                                    case maybeGraphData of
                                        Just _ ->
                                            model

                                        Nothing ->
                                            { model | activePage = GraphPage (Just (GraphData gotGraphData (initGraphModelForGraphPage gotGraphData) False Nothing)) }

                                _ ->
                                    model
                    in
                    ( newModel, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GoToContentViaContentGraph contentID ctrlIsPressed ->
            ( model
            , if ctrlIsPressed then
                openNewTab ("/contents/" ++ String.fromInt contentID ++ "?graph=true")

              else
                Nav.pushUrl model.key ("/contents/" ++ String.fromInt contentID ++ "?graph=true")
            )

        ColorizeContentOnGraph contentID ->
            ( case model.activePage of
                HomePage a maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            let
                                newGraphData =
                                    Just { gd | contentToColorize = Just contentID }

                                newHomePage =
                                    HomePage a newGraphData
                            in
                            { model | activePage = newHomePage }

                        Nothing ->
                            model

                GraphPage maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            { model | activePage = GraphPage (Just { gd | contentToColorize = Just contentID }) }

                        Nothing ->
                            model

                ContentPage data ->
                    case data of
                        NonInitialized _ ->
                            model

                        Initialized content ->
                            let
                                newGraphData =
                                    case content.graphDataIfGraphIsOn of
                                        Just gd ->
                                            Just { gd | contentToColorize = Just contentID }

                                        Nothing ->
                                            Nothing

                                newContent =
                                    { content | graphDataIfGraphIsOn = newGraphData }
                            in
                            { model | activePage = ContentPage (Initialized newContent) }

                _ ->
                    model
            , Cmd.none
            )

        UncolorizeContentOnGraph ->
            ( case model.activePage of
                HomePage a maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            let
                                newGraphData =
                                    Just { gd | contentToColorize = Nothing }

                                newHomePage =
                                    HomePage a newGraphData
                            in
                            { model | activePage = newHomePage }

                        Nothing ->
                            model

                GraphPage maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            { model | activePage = GraphPage (Just { gd | contentToColorize = Nothing }) }

                        Nothing ->
                            model

                ContentPage data ->
                    case data of
                        NonInitialized _ ->
                            model

                        Initialized content ->
                            let
                                newGraphData =
                                    case content.graphDataIfGraphIsOn of
                                        Just gd ->
                                            Just { gd | contentToColorize = Nothing }

                                        Nothing ->
                                            Nothing

                                newContent =
                                    { content | graphDataIfGraphIsOn = newGraphData }
                            in
                            { model | activePage = ContentPage (Initialized newContent) }

                _ ->
                    model
            , Cmd.none
            )

        otherMsg ->
            case model.activePage of
                HomePage allTags maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            let
                                newGraphData =
                                    Just (GraphData gd.graphData (updateGraph otherMsg gd.graphModel) True gd.contentToColorize)

                                newHomePage =
                                    HomePage allTags newGraphData
                            in
                            ( { model | activePage = newHomePage }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                GraphPage maybeGraphData ->
                    case maybeGraphData of
                        Just gd ->
                            let
                                newGraphData =
                                    GraphData gd.graphData (updateGraph otherMsg gd.graphModel) True gd.contentToColorize

                                newGraphPage =
                                    GraphPage (Just newGraphData)
                            in
                            ( { model | activePage = newGraphPage }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                ContentPage data ->
                    case data of
                        Initialized content ->
                            case content.graphDataIfGraphIsOn of
                                Just gd ->
                                    let
                                        newGraphData =
                                            Just (GraphData gd.graphData (updateGraph otherMsg gd.graphModel) True gd.contentToColorize)

                                        newContentPage =
                                            ContentPage (Initialized { content | graphDataIfGraphIsOn = newGraphData })
                                    in
                                    ( { model | activePage = newContentPage }, Cmd.none )

                                Nothing ->
                                    ( model, Cmd.none )

                        NonInitialized _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.activePage of
        HomePage allTags maybeGraphData ->
            case maybeGraphData of
                Just gd ->
                    let
                        totalTagCountCurrentlyShownOnPage =
                            tagCountCurrentlyShownOnPage allTags
                    in
                    graphSubscriptions gd.graphModel totalTagCountCurrentlyShownOnPage

                Nothing ->
                    Sub.none

        GraphPage maybeGraphData ->
            case maybeGraphData of
                Just gd ->
                    graphSubscriptionsForGraph gd.graphModel

                Nothing ->
                    Sub.none

        ContentPage data ->
            case data of
                Initialized content ->
                    case content.graphDataIfGraphIsOn of
                        Just gd ->
                            graphSubscriptionsForContent gd.graphModel

                        Nothing ->
                            Sub.none

                NonInitialized _ ->
                    Sub.none

        _ ->
            Sub.none
