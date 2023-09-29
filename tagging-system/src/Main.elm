module Main exposing (main)

import App.Model exposing (..)
import App.Msg exposing (ContentInputTypeForContentCreation(..), ContentInputTypeForContentUpdate(..), Msg(..), TagInputType(..))
import App.Ports exposing (sendTitle)
import App.UrlParser exposing (pageBy)
import App.View exposing (view)
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Component.Page.Util exposing (tagsNotLoaded)
import Content.Util exposing (gotContentToContent)
import DataResponse exposing (ContentID)
import List
import Requests exposing (createNewTag, getContent, getInitialData, getSearchResult, getTagContents, getTimeZone, createNewContent, updateContent, updateTag)
import Tag.Util exposing (tagById)
import TagTextPart.Util exposing (toGotTagTextPartToTagTextPart)
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
            Model "log" key [] "" page LocalStorage False Time.utc
    in
    ( model
    , Cmd.batch [ getCmdToSendByPage model, getTimeZone ]
    )


getCmdToSendByPage : Model -> Cmd Msg
getCmdToSendByPage model =
    Cmd.batch
        [ sendTitle model
        , if tagsNotLoaded model then
            getInitialData

          else
            case model.activePage of
                TagPage status ->
                    case status of
                        NonInitialized initializableTagPageModel ->
                            let
                                tagId =
                                    case initializableTagPageModel.tagId of
                                        HomeInput ->
                                            model.homeTagId

                                        IdInput id ->
                                            id
                            in
                            case tagById model.allTags tagId of
                                Just tag ->
                                    getTagContents tag

                                Nothing ->
                                    Cmd.none

                        Initialized _ ->
                            Cmd.none

                ContentPage status ->
                    case status of
                        NonInitialized contentId ->
                            getContent contentId

                        Initialized _ ->
                            Cmd.none

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

        GotInitialDataResponse res ->
            case res of
                Ok got ->
                    let
                        newModel =
                            { model | allTags = got.allTags, homeTagId = got.homeTagId }
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

                        newActivePage =
                            case model.activePage of
                                ContentPage (NonInitialized _) ->
                                    ContentPage <| Initialized content

                                _ ->
                                    MaintenancePage

                        newModel =
                            { model | activePage = newActivePage }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        GotContentCreationResponse result ->
            case result of
                Ok _ ->
                    let
                        newActivePage =
                            case model.activePage of
                                TagPage (Initialized a) ->
                                    TagPage (Initialized { a | createContentModule = defaultCreateContentModuleModelData })

                                _ ->
                                    MaintenancePage

                        newModel =
                            { model | activePage = newActivePage }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        GotContentUpdateResponse result ->
            case result of
                Ok gotContent ->
                    let
                        content =
                            gotContentToContent model gotContent

                        newActivePage : Page
                        newActivePage =
                            case model.activePage of
                                TagPage (Initialized a) ->
                                    case a.updateContentModule.model of
                                        NotInitializedYet _ ->
                                            TagPage (Initialized { a | updateContentModule = { isVisible = True, model = GotContentToUpdate (setUpdateContentPageModel content) } })

                                        GotContentToUpdate _ ->
                                            TagPage (Initialized { a | updateContentModule = { isVisible = True, model = GotContentToUpdate (setUpdateContentPageModel content) } })

                                        UpdateRequestIsSent _ ->
                                            TagPage (Initialized { a | updateContentModule = defaultUpdateContentModuleModelData })

                                _ ->
                                    MaintenancePage

                        newModel =
                            { model | activePage = newActivePage }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- TAG PAGE --
        GotDataOfTag tag result ->
            case result of
                Ok tagDataResponse ->
                    case model.activePage of
                        TagPage status ->
                            case status of
                                NonInitialized _ ->
                                    let
                                        tagTextParts =
                                            List.map (toGotTagTextPartToTagTextPart model) tagDataResponse.textParts

                                        newPage =
                                            TagPage <|
                                                Initialized (InitializedTagPageModel tag tagTextParts defaultCreateContentModuleModelData defaultUpdateContentModuleModelData defaultCreateTagModuleModelData defaultUpdateTagModuleModelData)

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
        CreateContentModuleInputChanged inputType input ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        currentCreateContentModuleModel =
                            tagPage.createContentModule.model

                        newCreateContentModuleModel : CreateContentModuleModel
                        newCreateContentModuleModel =
                            case inputType of
                                Title ->
                                    { currentCreateContentModuleModel | title = input }

                                Text ->
                                    { currentCreateContentModuleModel | text = input }

                                Tags ->
                                    { currentCreateContentModuleModel | tags = input }

                        currentModule =
                            tagPage.createContentModule

                        newModule : CreateContentModuleModelData
                        newModule =
                            { currentModule | model = newCreateContentModuleModel }

                        newTagPage =
                            TagPage (Initialized { tagPage | createContentModule = newModule })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        UpdateContentModuleInputChanged inputType input ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        currentUpdateContentModuleModel =
                            tagPage.updateContentModule.model

                        newUpdateContentModuleModel : UpdateContentModuleModel
                        newUpdateContentModuleModel =
                            case currentUpdateContentModuleModel of
                                GotContentToUpdate updateContentPageData ->
                                    GotContentToUpdate <|
                                        case inputType of
                                            TitleU ->
                                                { updateContentPageData | title = input }

                                            TextU ->
                                                { updateContentPageData | text = input }

                                            TagsU ->
                                                { updateContentPageData | tags = input }

                                other ->
                                    other

                        currentModule =
                            tagPage.updateContentModule

                        newModule : UpdateContentModuleModelData
                        newModule =
                            { currentModule | model = newUpdateContentModuleModel }

                        newTagPage =
                            TagPage (Initialized { tagPage | updateContentModule = newModule })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        CreateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model, createNewContent a.createContentModule.model )

                _ ->
                    ( model, Cmd.none )

        ToggleCreateContentModule bool ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentCreateContentModule : CreateContentModuleModelData
                        currentCreateContentModule =
                            a.createContentModule

                        newCreateContentModule : CreateContentModuleModelData
                        newCreateContentModule =
                            { currentCreateContentModule | isVisible = bool }

                        newA =
                            { a | createContentModule = newCreateContentModule }

                        newModel =
                            { model | activePage = TagPage (Initialized newA) }
                    in
                    ( newModel, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let

                        currentUpdateContentModuleModel : UpdateContentModuleModel
                        currentUpdateContentModuleModel =
                            a.updateContentModule.model

                        updateContentModuleData = case currentUpdateContentModuleModel of
                            GotContentToUpdate u ->
                                u

                            _ ->
                                UpdateContentModuleData 0 "" "" ""

                        currentUpdateContentModule = a.updateContentModule

                        newUpdateContentModule =
                            { currentUpdateContentModule | model = GotContentToUpdate updateContentModuleData }

                        newTagPage = TagPage (Initialized { a | updateContentModule = newUpdateContentModule })
                    in
                    ( { model | activePage = newTagPage }, updateContent updateContentModuleData.contentId updateContentModuleData )

                _ ->
                    ( model, Cmd.none )

        -- CREATE TAG MODULE --
        CreateTagModuleInputChanged inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentCreateTagModuleModel = a.createTagModule.model

                        newCreateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentCreateTagModuleModel | name = input }

                                InfoContentId _ ->
                                    a.createTagModule.model

                        currentCreateTagModule = a.createTagModule
                        newCreateTagModule = { currentCreateTagModule | model = newCreateTagModuleModel }

                        newTagPage = TagPage (Initialized { a | createTagModule = newCreateTagModule })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        -- UPDATE TAG MODULE --
        UpdateTagModuleInputChanged inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentUpdateTagModuleModel : UpdateTagModuleModel
                        currentUpdateTagModuleModel = a.updateTagModule.model

                        newUpdateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentUpdateTagModuleModel | name = input }

                                InfoContentId _ ->
                                    a.updateTagModule.model

                        currentUpdateTagModule = a.updateTagModule
                        newUpdateTagModule = { currentUpdateTagModule | model = newUpdateTagModuleModel }

                        newTagPage = TagPage (Initialized { a | updateTagModule = newUpdateTagModule })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CreateTag ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model, createNewTag a.createTagModule.model )

                _ ->
                    ( model, Cmd.none )

        ToggleCreateTagModule bool ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentCreateTagModule : CreateTagModuleModelData
                        currentCreateTagModule =
                            a.createTagModule

                        newCreateTagModule : CreateTagModuleModelData
                        newCreateTagModule =
                            { currentCreateTagModule | isVisible = bool }

                        newA =
                            { a | createTagModule = newCreateTagModule }

                        newModel =
                            { model | activePage = TagPage (Initialized newA) }
                    in
                    ( newModel, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateTag ->
                case model.activePage of
                    TagPage (Initialized a) ->
                        ( model, updateTag a.updateTagModule.model )

                    _ ->
                        ( model, Cmd.none )

        GotTagUpdateOrCreationDoneResponse res ->
            case res of
                Ok message ->
                    let
                        newActivePage =
                            if message == "done" then
                                homepage

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
                        TagPage _ ->
                            ContentSearchPage searchKeyword []

                        ContentSearchPage _ contentList ->
                            ContentSearchPage searchKeyword contentList

                        _ ->
                            model.activePage

                newModel =
                    { model | activePage = newPage }

                getAllTagsCmdMsg =
                    case model.activePage of
                        TagPage _ ->
                            getCmdToSendByPage newModel

                        _ ->
                            Cmd.none
            in
            ( newModel, Cmd.batch [ sendTitle newModel, getAllTagsCmdMsg, getSearchResult searchKeyword, Dom.focus "contentSearchInput" |> Task.attempt FocusResult ] )

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

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
