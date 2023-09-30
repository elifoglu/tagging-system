module Main exposing (main)

import App.Model exposing (..)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), Msg(..), TagInputType(..), TagPickerInputType(..), WorkingOnWhichModule(..))
import App.Ports exposing (sendTitle)
import App.UrlParser exposing (pageBy)
import App.View exposing (view)
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Component.Page.Util exposing (tagsNotLoaded)
import Content.Model exposing (Content)
import Content.Util exposing (gotContentToContent)
import DataResponse exposing (ContentID)
import List
import Requests exposing (createContent, createTag, getContent, getInitialData, getSearchResult, getTagContents, getTimeZone, updateContent, updateTag)
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
                                    TagPage (Initialized { a | createContentModule = defaultCreateContentModule model.allTags })

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
                                                Initialized (InitializedTagPageModel tag tagTextParts (defaultCreateContentModule model.allTags) defaultUpdateContentModule (defaultCreateTagModuleModel model.allTags) (defaultUpdateTagModuleModel tag model.allTags) CreateContentModuleIsVisible CreateTagModuleIsVisible)

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
                            tagPage.createContentModule

                        newCreateContentModuleModel : CreateContentModuleModel
                        newCreateContentModuleModel =
                            case inputType of
                                Title ->
                                    { currentCreateContentModuleModel | title = input }

                                Text ->
                                    { currentCreateContentModuleModel | text = input }

                        newTagPage =
                            TagPage (Initialized { tagPage | createContentModule = newCreateContentModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        UpdateContentModuleInputChanged inputType input ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        currentUpdateContentModuleModel : UpdateContentModuleModel
                        currentUpdateContentModuleModel =
                            tagPage.updateContentModule

                        newUpdateContentModuleModel : UpdateContentModuleModel
                        newUpdateContentModuleModel =
                            case inputType of
                                Title ->
                                    { currentUpdateContentModuleModel | title = input }

                                Text ->
                                    { currentUpdateContentModuleModel | text = input }

                        newTagPage =
                            TagPage (Initialized { tagPage | updateContentModule = newUpdateContentModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model MaintenancePage

        CreateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model, createContent a.createContentModule )

                _ ->
                    ( model, Cmd.none )

        UpdateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model, updateContent a.updateContentModule )

                _ ->
                    ( model, Cmd.none )

        ToggleUpdateContentModuleFor content ->
                case model.activePage of
                    TagPage (Initialized a) ->
                        let
                            setUpdateContentPageModel : Content -> UpdateContentModuleModel
                            setUpdateContentPageModel c =
                                { contentId = c.contentId
                                , title = Maybe.withDefault "" c.title
                                , text = c.text
                                , tagPickerModelForTags = (TagPickerModuleModel "" (allTagOptions model.allTags) (selectedTagOptionsForContent c model.allTags) Nothing)
                                }

                            newUpdateContentModuleModel : UpdateContentModuleModel
                            newUpdateContentModuleModel = setUpdateContentPageModel content

                            newTagPage =
                                TagPage (Initialized { a | updateContentModule = newUpdateContentModuleModel, oneOfContentModuleIsVisible = UpdateContentModuleIsVisible })

                        in
                        ( { model | activePage = newTagPage }, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

        -- CREATE TAG MODULE --
        CreateTagModuleInputChanged inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentCreateTagModuleModel =
                            a.createTagModuleModel

                        newCreateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentCreateTagModuleModel | name = input }

                                Description input ->
                                    { currentCreateTagModuleModel | description = input }

                        newTagPage =
                            TagPage (Initialized { a | createTagModuleModel = newCreateTagModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        -- UPDATE TAG MODULE --
        ToggleUpdateTagModuleVisibility ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        otherOneIsVisible =
                            case a.oneOfTagModuleIsVisible of
                                UpdateTagModuleIsVisible ->
                                    CreateTagModuleIsVisible

                                CreateTagModuleIsVisible ->
                                    UpdateTagModuleIsVisible

                        newTagPage =
                            TagPage (Initialized { a | oneOfTagModuleIsVisible = otherOneIsVisible })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateTagModuleInputChanged inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentUpdateTagModuleModel : UpdateTagModuleModel
                        currentUpdateTagModuleModel =
                            a.updateTagModuleModel

                        newUpdateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentUpdateTagModuleModel | name = input }

                                Description input ->
                                    { currentUpdateTagModuleModel | description = input }

                        newTagPage =
                            TagPage (Initialized { a | updateTagModuleModel = newUpdateTagModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TagPickerModuleInputChanged workingOnWhichModule inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentTagPickerModuleModel =
                            case workingOnWhichModule of
                                WorkingOnCreateTagModule ->
                                    a.createTagModuleModel.tagPickerModelForParentTags

                                WorkingOnUpdateTagModule ->
                                    a.updateTagModuleModel.tagPickerModelForParentTags

                                WorkingOnCreateContentModule ->
                                    a.createContentModule.tagPickerModelForTags

                                WorkingOnUpdateContentModule ->
                                    a.createContentModule.tagPickerModelForTags

                        newTagPickerModuleModel =
                            case inputType of
                                SearchInput text ->
                                    { currentTagPickerModuleModel | input = text }

                                OptionClicked tagOption ->
                                    let
                                        newSelectedTagOptions =
                                            currentTagPickerModuleModel.selectedTagOptions ++ [ tagOption ]
                                    in
                                    { currentTagPickerModuleModel | selectedTagOptions = newSelectedTagOptions }

                                OptionRemoved tagOption ->
                                    let
                                        newSelectedTagOptions =
                                            currentTagPickerModuleModel.selectedTagOptions
                                                |> List.filter (\t -> t.tagId /= tagOption.tagId)
                                    in
                                    { currentTagPickerModuleModel | selectedTagOptions = newSelectedTagOptions }

                        newTagPage =
                            case workingOnWhichModule of
                                WorkingOnCreateTagModule ->
                                    let
                                        currentCreateTagModuleModel =
                                            a.createTagModuleModel

                                        newCreateTagModuleModel =
                                            { currentCreateTagModuleModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | createTagModuleModel = newCreateTagModuleModel })

                                WorkingOnUpdateTagModule ->
                                    let
                                        currentUpdateTagPageModel =
                                            a.updateTagModuleModel

                                        newUpdateTagModuleModel =
                                            { currentUpdateTagPageModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | updateTagModuleModel = newUpdateTagModuleModel })

                                WorkingOnCreateContentModule ->
                                    let
                                        currentCreateContentModuleModel =
                                            a.createContentModule

                                        newCreateContentModuleModel =
                                            { currentCreateContentModuleModel | tagPickerModelForTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | createContentModule = newCreateContentModuleModel })

                                WorkingOnUpdateContentModule ->
                                    let
                                        currentUpdateContentModuleModel =
                                            a.updateContentModule

                                        newUpdateContentModuleModel =
                                            { currentUpdateContentModuleModel | tagPickerModelForTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | updateContentModule = newUpdateContentModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CreateTag ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , if a.createTagModuleModel.name == "" then
                        Cmd.none

                      else
                        createTag a.createTagModuleModel
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateTag ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , if a.updateTagModuleModel.name == "" then
                        Cmd.none

                      else
                        updateTag a.updateTagModuleModel
                    )

                _ ->
                    ( model, Cmd.none )

        GotTagOrContentCreateUpdateDeleteDoneResponse res ->
            case res of
                Ok message ->
                    let
                        newActivePage =
                            case model.activePage of
                                TagPage (Initialized a) ->
                                    if message == "done" then
                                        TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput a.tag.tagId)))
                                        -- This is just to reinitialize the page to see newly created tags etc. in the page instantly

                                    else
                                        NotFoundPage

                                _ ->
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
