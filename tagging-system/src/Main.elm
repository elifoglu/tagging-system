module Main exposing (main)

import App.Model exposing (..)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), CrudAction(..), KeyDownPlace(..), Msg(..), TagInputType(..), TagPickerInputType(..), WorkingOnWhichModule(..))
import App.Ports exposing (sendTitle, storeTagTextViewType, storeTheme)
import App.UrlParser exposing (pageBy)
import App.View exposing (view)
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Nav
import Component.Page.Util exposing (tagsNotLoaded)
import Content.Model exposing (Content)
import Content.Util exposing (gotContentToContent)
import DataResponse exposing (ContentID)
import Html.Events.Extra.Mouse as Mouse exposing (Event)
import Json.Decode as Decode
import List
import List.Extra
import Process
import Requests exposing (createContent, createContentViaQuickContentAdder, createTag, deleteContent, deleteTag, dragContent, getInitialData, getSearchResult, getTagContents, getTimeZone, undo, updateContent, updateContentViaQuickContentEditor, updateTag)
import Tag.Util exposing (tagById)
import TagTextPart.Model exposing (TagTextPart)
import TagTextPart.Util exposing (toGotTagTextPartToTagTextPart)
import Task
import Time
import Tuple exposing (first, second)
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


init : { activeTheme: Maybe String, tagTextViewType : Maybe String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        page =
            pageBy url

        tagTextViewType =
            case flags.tagTextViewType of
                Just "group" ->
                    GroupView

                Just "line" ->
                    LineView

                Just "distinct-group" ->
                    DistinctGroupView

                _ ->
                    GroupView

        activeTheme =
            case flags.activeTheme of
                Just "light" ->
                    Light

                Just "dark" ->
                    Dark

                _ ->
                    Light

        model =
            Model "log" key [] "" False Nothing Nothing page (LocalStorage activeTheme tagTextViewType) False Time.utc Nothing activeTheme
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
                            { model | allTags = got.allTags, homeTagId = got.homeTagId, undoable = got.undoable }
                    in
                    ( newModel, getCmdToSendByPage newModel )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        GotTagOrContentCreateUpdateDeleteDoneResponse crudAction res ->
            case res of
                Ok message ->
                    case model.activePage of
                        TagPage (Initialized a) ->
                            if message == "done" then
                                case crudAction of
                                    DeleteTagAct ->
                                        ( model, Nav.pushUrl model.key "/" )

                                    CreateContentActViaQuickContentAdder ->
                                        let
                                            quickContentAdderData =
                                                case a.quickContentAdderModule of
                                                    JustQuickContentAdderData quickContentAdderLocation _ ->
                                                        Just quickContentAdderLocation

                                                    NothingButTextToStore _ ->
                                                        Nothing

                                            newModel =
                                                { model | previousQuickContentAdderLocationToKeepOpenAfterEnter = quickContentAdderData, allTags = [], activePage = TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput a.tag.tagId))) }
                                        in
                                        ( newModel, getCmdToSendByPage newModel )

                                    _ ->
                                        let
                                            newModel =
                                                { model | allTags = [], activePage = TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput a.tag.tagId))) }
                                        in
                                        ( newModel, getCmdToSendByPage newModel )
                                -- This is just to reinitialize the page to see newly created tags etc. in the page instantly

                            else
                                ( model, Cmd.none )

                        _ ->
                            ( { model | activePage = NotFoundPage }, Cmd.none )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- TAG PAGE --
        GotTagTextOfTag tag result ->
            case result of
                Ok tagDataResponse ->
                    case model.activePage of
                        TagPage status ->
                            case status of
                                NonInitialized _ ->
                                    let
                                        tagTextPartsForLineView =
                                            List.map (toGotTagTextPartToTagTextPart model) tagDataResponse.textPartsForLineView

                                        tagTextPartsForGroupView =
                                            List.map (toGotTagTextPartToTagTextPart model) tagDataResponse.textPartsForGroupView

                                        tagTextPartsForDistinctGroupView =
                                            List.map (toGotTagTextPartToTagTextPart model) tagDataResponse.textPartsForDistinctGroupView

                                        quickContentAdderModuleWithFocusCmd =
                                            case model.previousQuickContentAdderLocationToKeepOpenAfterEnter of
                                                Just prevQuickContentAdderLocation ->
                                                    let
                                                        relatedTagTextPart =
                                                            case model.localStorage.tagTextViewType of
                                                                LineView ->
                                                                    tagTextPartsForLineView

                                                                GroupView ->
                                                                    tagTextPartsForGroupView

                                                                DistinctGroupView ->
                                                                    tagTextPartsForDistinctGroupView

                                                        quickContentAdderLocationInNextLine =
                                                            findNextLocationOfQuickContentAdder relatedTagTextPart prevQuickContentAdderLocation model.localStorage.tagTextViewType
                                                    in
                                                    ( quickContentAdderLocationInNextLine, Dom.focus "quickContentAdder" |> Task.attempt FocusResult )

                                                Nothing ->
                                                    ( NothingButTextToStore "", Cmd.none )

                                        newPage =
                                            TagPage <|
                                                Initialized (InitializedTagPageModel tag tagTextPartsForLineView tagTextPartsForGroupView tagTextPartsForDistinctGroupView model.localStorage.tagTextViewType (defaultCreateContentModule tag model.allTags) defaultUpdateContentModule (defaultCreateTagModule model.allTags) (defaultUpdateTagModule tag model.allTags) CreateContentModuleIsVisible CreateTagModuleIsVisible (first quickContentAdderModuleWithFocusCmd) (ClosedButTextToStore dummyContent ""))

                                        newModel =
                                            { model | activePage = newPage, previousQuickContentAdderLocationToKeepOpenAfterEnter = Nothing }
                                    in
                                    ( newModel, Cmd.batch [ second quickContentAdderModuleWithFocusCmd, getCmdToSendByPage newModel ] )

                                _ ->
                                    createNewModelAndCmdMsg model NotFoundPage

                        _ ->
                            createNewModelAndCmdMsg model NotFoundPage

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        ChangeTagTextViewTypeSelection selection ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        newTagPage =
                            TagPage (Initialized { a | activeTagTextViewType = selection, quickContentAdderModule = NothingButTextToStore "" })

                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | tagTextViewType = selection }
                    in
                    ( { model | activePage = newTagPage, localStorage = newLocalStorage }
                    , storeTagTextViewType
                        (case selection of
                            GroupView ->
                                "group"

                            LineView ->
                                "line"

                            DistinctGroupView ->
                                "distinct-group"
                        )
                    )

                _ ->
                    ( model, Cmd.none )

        ThemeChanged selection ->
                let
                    localStorage =
                        model.localStorage

                    newLocalStorage =
                        { localStorage | activeTheme = selection }

                in
                ( { model | activeTheme = selection, localStorage = newLocalStorage }
                , storeTheme
                    (case selection of
                        Light ->
                            "light"

                        Dark ->
                               "dark"
                    )
                )


        -- CREATE/UPDATE CONTENT MODULES --
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
                    createNewModelAndCmdMsg model NotFoundPage

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
                    createNewModelAndCmdMsg model NotFoundPage

        CreateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , if String.trim a.createContentModule.text == "" then
                        Cmd.none

                      else
                        createContent a.createContentModule
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateContent ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , if String.trim a.updateContentModule.text == "" then
                        Cmd.none

                      else
                        updateContent a.updateContentModule
                    )

                _ ->
                    ( model, Cmd.none )

        DeleteContent content ->
            ( model, deleteContent content.contentId )

        ToggleUpdateContentModuleFor content ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        setUpdateContentPageModel : Content -> UpdateContentModuleModel
                        setUpdateContentPageModel c =
                            { content = c
                            , title = Maybe.withDefault "" c.title
                            , text = c.text
                            , tagPickerModelForTags = TagPickerModuleModel "" (allTagOptions model.allTags) False (selectedTagOptionsForContent c model.allTags) Nothing
                            }

                        newUpdateContentModuleModel : UpdateContentModuleModel
                        newUpdateContentModuleModel =
                            setUpdateContentPageModel content

                        newTagPage =
                            TagPage (Initialized { a | updateContentModule = newUpdateContentModuleModel, oneOfContentModuleIsVisible = UpdateContentModuleIsVisible })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ToggleQuickContentAdderBox contentId tagIdOfTagPage tagIdOfTextPartThatContentBelongs locatedAt prevLineContentId nextLineContentId ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        quickContentAdderModule =
                            tagPage.quickContentAdderModule

                        newQuickContentAdderModelWithFocusMsg : ( QuickContentAdderModel, Cmd Msg )
                        newQuickContentAdderModelWithFocusMsg =
                            case quickContentAdderModule of
                                JustQuickContentAdderData boxLocation text ->
                                    if boxLocation == QuickContentAdderLocation contentId tagIdOfTextPartThatContentBelongs tagIdOfTagPage locatedAt prevLineContentId nextLineContentId then
                                        ( NothingButTextToStore text, Cmd.none )

                                    else
                                        ( JustQuickContentAdderData (QuickContentAdderLocation contentId tagIdOfTextPartThatContentBelongs tagIdOfTagPage locatedAt prevLineContentId nextLineContentId) text, Dom.focus "quickContentAdder" |> Task.attempt FocusResult )

                                NothingButTextToStore textToStore ->
                                    ( JustQuickContentAdderData (QuickContentAdderLocation contentId tagIdOfTextPartThatContentBelongs tagIdOfTagPage locatedAt prevLineContentId nextLineContentId) textToStore, Dom.focus "quickContentAdder" |> Task.attempt FocusResult )

                        newTagPage =
                            TagPage (Initialized { tagPage | quickContentAdderModule = first newQuickContentAdderModelWithFocusMsg })
                    in
                    ( { model | activePage = newTagPage }, second newQuickContentAdderModelWithFocusMsg )

                _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        QuickContentAdderInputChanged text ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        currentQuickContentAdderModuleModel =
                            tagPage.quickContentAdderModule

                        newQuickContentAdderModuleModel =
                            case currentQuickContentAdderModuleModel of
                                JustQuickContentAdderData boxLocation _ ->
                                    JustQuickContentAdderData boxLocation text

                                NothingButTextToStore textToStore ->
                                    NothingButTextToStore textToStore

                        newTagPage =
                            TagPage (Initialized { tagPage | quickContentAdderModule = newQuickContentAdderModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        OpenQuickContentEditInput content ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        prevQuickContentEditModule =
                            tagPage.quickContentEditModule

                        textToPut =
                            case prevQuickContentEditModule of
                                Open _ _ ->
                                    content.text

                                ClosedButTextToStore contentLineOfClosedQuickEditModule prevTextOfPreviouslyOpenedButLaterClosedQuickEditBox ->
                                    if
                                        contentLineOfClosedQuickEditModule.contentId
                                            == content.contentId
                                            && contentLineOfClosedQuickEditModule.tagIdOfCurrentTextPart
                                            == content.tagIdOfCurrentTextPart
                                    then
                                        prevTextOfPreviouslyOpenedButLaterClosedQuickEditBox

                                    else
                                        content.text

                        newTagPage =
                            TagPage (Initialized { tagPage | quickContentEditModule = Open content textToPut })
                    in
                    ( { model | activePage = newTagPage }, Cmd.batch [ Dom.focus "quickEditBox" |> Task.attempt FocusResult ] )

                _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        GotContentLineElementToGetItsHeight (Ok element) ->
            let
                height =
                    element.element.height

                new =
                    case model.contentTagDuoWhichCursorIsOverItNow of
                        Just a ->
                            Just { a | contentLineHeight = height }

                        Nothing ->
                            Nothing
            in
            ( { model | contentTagDuoWhichCursorIsOverItNow = new }, Cmd.none )

        QuickContentEditInputChanged text ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    let
                        currentQuickContentEditModuleModel =
                            tagPage.quickContentEditModule

                        newQuickContentEditModuleModel =
                            case currentQuickContentEditModuleModel of
                                Open content _ ->
                                    Open content text

                                _ ->
                                    ClosedButTextToStore dummyContent ""

                        newTagPage =
                            TagPage (Initialized { tagPage | quickContentEditModule = newQuickContentEditModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        KeyDown keyDownPlace keyDownType ->
            case keyDownPlace of
                QuickContentAdderInput ->
                    case keyDownType of
                        App.Msg.Enter ->
                            case model.activePage of
                                TagPage (Initialized tagPage) ->
                                    case tagPage.quickContentAdderModule of
                                        JustQuickContentAdderData boxLocation text ->
                                            ( model
                                            , if tagPage.activeTagTextViewType /= GroupView && String.trim text == "" then
                                                Cmd.none

                                              else
                                                createContentViaQuickContentAdder text
                                                    boxLocation.contentLineTagId
                                                    boxLocation.tagIdOfActiveTagPage
                                                    tagPage.activeTagTextViewType
                                                    boxLocation.contentLineContentId
                                                    (case boxLocation.locatedAt of
                                                        BeforeContentLine ->
                                                            "front"

                                                        AfterContentLine ->
                                                            "back"
                                                    )
                                            )

                                        NothingButTextToStore _ ->
                                            ( model, Cmd.none )

                                _ ->
                                    ( model, Cmd.none )

                        App.Msg.ShiftEnter ->
                            ( model, Cmd.none )

                        App.Msg.Escape ->
                            case model.activePage of
                                TagPage (Initialized tagPage) ->
                                    case tagPage.quickContentAdderModule of
                                        JustQuickContentAdderData _ text ->
                                            ( { model | activePage = TagPage (Initialized { tagPage | quickContentAdderModule = NothingButTextToStore (String.trim text) }) }, Cmd.none )

                                        NothingButTextToStore _ ->
                                            ( model, Cmd.none )

                                _ ->
                                    ( model, Cmd.none )

                        App.Msg.OtherSoNoOp ->
                            ( model, Cmd.none )

                QuickContentEditInput ->
                    case keyDownType of
                        App.Msg.Enter ->
                            case model.activePage of
                                TagPage (Initialized tagPage) ->
                                    case tagPage.quickContentEditModule of
                                        Open content updatedText ->
                                            ( model
                                            , if tagPage.activeTagTextViewType /= GroupView && String.trim updatedText == "" then
                                                Cmd.none

                                              else
                                                updateContentViaQuickContentEditor content updatedText
                                            )

                                        ClosedButTextToStore _ _ ->
                                            ( model, Cmd.none )

                                _ ->
                                    ( model, Cmd.none )

                        App.Msg.ShiftEnter ->
                            ( model, Cmd.none )

                        App.Msg.Escape ->
                            case model.activePage of
                                TagPage (Initialized tagPage) ->
                                    case tagPage.quickContentEditModule of
                                        Open content textToStore ->
                                            ( { model | activePage = TagPage (Initialized { tagPage | quickContentEditModule = ClosedButTextToStore content textToStore }) }, Cmd.none )

                                        ClosedButTextToStore _ _ ->
                                            ( model, Cmd.none )

                                _ ->
                                    ( model, Cmd.none )

                        App.Msg.OtherSoNoOp ->
                            ( model, Cmd.none )

                SearchInputOnSearchPage ->
                    case keyDownType of
                        App.Msg.Escape ->
                            case model.activePage of
                                ContentSearchPage _ _ tagIdToReturnItsPage ->
                                    let
                                        newModel =
                                            { model | allTags = [], activePage = TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput tagIdToReturnItsPage))) }
                                    in
                                    ( newModel, getCmdToSendByPage newModel )

                                _ ->
                                    ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                TagPickerModuleInput workingOnWhichModule ->
                    case keyDownType of
                        App.Msg.Escape ->
                            case model.activePage of
                                TagPage (Initialized a) ->
                                    let
                                        currentTagPickerModuleModel : TagPickerModuleModel
                                        currentTagPickerModuleModel =
                                            case workingOnWhichModule of
                                                WorkingOnCreateTagModule ->
                                                    a.createTagModule.tagPickerModelForParentTags

                                                WorkingOnUpdateTagModule ->
                                                    a.updateTagModule.tagPickerModelForParentTags

                                                WorkingOnCreateContentModule ->
                                                    a.createContentModule.tagPickerModelForTags

                                                WorkingOnUpdateContentModule ->
                                                    a.updateContentModule.tagPickerModelForTags

                                        newTagPickerModuleModel =
                                            { currentTagPickerModuleModel | showTagOptionList = False, input = "" }

                                        newTagPage =
                                            case workingOnWhichModule of
                                                WorkingOnCreateTagModule ->
                                                    let
                                                        currentCreateTagModuleModel =
                                                            a.createTagModule

                                                        newCreateTagModuleModel =
                                                            { currentCreateTagModuleModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                                    in
                                                    TagPage (Initialized { a | createTagModule = newCreateTagModuleModel })

                                                WorkingOnUpdateTagModule ->
                                                    let
                                                        currentUpdateTagPageModel =
                                                            a.updateTagModule

                                                        newUpdateTagModuleModel =
                                                            { currentUpdateTagPageModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                                    in
                                                    TagPage (Initialized { a | updateTagModule = newUpdateTagModuleModel })

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

                        _ ->
                            ( model, Cmd.none )

        -- CREATE/UPDATE TAG MODULES --
        CreateTagModuleInputChanged inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentCreateTagModuleModel =
                            a.createTagModule

                        newCreateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentCreateTagModuleModel | name = input }

                                Description input ->
                                    { currentCreateTagModuleModel | description = input }

                        newTagPage =
                            TagPage (Initialized { a | createTagModule = newCreateTagModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

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
                            a.updateTagModule

                        newUpdateTagModuleModel =
                            case inputType of
                                Name input ->
                                    { currentUpdateTagModuleModel | name = input }

                                Description input ->
                                    { currentUpdateTagModuleModel | description = input }

                        newTagPage =
                            TagPage (Initialized { a | updateTagModule = newUpdateTagModuleModel })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TagPickerModuleInputChanged workingOnWhichModule inputType ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentTagPickerModuleModel : TagPickerModuleModel
                        currentTagPickerModuleModel =
                            case workingOnWhichModule of
                                WorkingOnCreateTagModule ->
                                    a.createTagModule.tagPickerModelForParentTags

                                WorkingOnUpdateTagModule ->
                                    a.updateTagModule.tagPickerModelForParentTags

                                WorkingOnCreateContentModule ->
                                    a.createContentModule.tagPickerModelForTags

                                WorkingOnUpdateContentModule ->
                                    a.updateContentModule.tagPickerModelForTags

                        newTagPickerModuleModel =
                            case inputType of
                                SearchInput text ->
                                    { currentTagPickerModuleModel | input = text, showTagOptionList = True }

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

                                ToggleSelectionList ->
                                    { currentTagPickerModuleModel | showTagOptionList = not currentTagPickerModuleModel.showTagOptionList }

                        newTagPage =
                            case workingOnWhichModule of
                                WorkingOnCreateTagModule ->
                                    let
                                        currentCreateTagModuleModel =
                                            a.createTagModule

                                        newCreateTagModuleModel =
                                            { currentCreateTagModuleModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | createTagModule = newCreateTagModuleModel })

                                WorkingOnUpdateTagModule ->
                                    let
                                        currentUpdateTagPageModel =
                                            a.updateTagModule

                                        newUpdateTagModuleModel =
                                            { currentUpdateTagPageModel | tagPickerModelForParentTags = newTagPickerModuleModel }
                                    in
                                    TagPage (Initialized { a | updateTagModule = newUpdateTagModuleModel })

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
                    , if a.createTagModule.name == "" then
                        Cmd.none

                      else
                        createTag a.createTagModule
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateTag ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , if a.updateTagModule.name == "" then
                        Cmd.none

                      else
                        updateTag a.updateTagModule
                    )

                _ ->
                    ( model, Cmd.none )

        ChangeTagDeleteStrategySelection selection ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        currentUpdateTagModule : UpdateTagModuleModel
                        currentUpdateTagModule =
                            a.updateTagModule

                        newUpdateTagModule =
                            { currentUpdateTagModule | tagDeleteStrategy = selection }

                        newTagPage =
                            TagPage (Initialized { a | updateTagModule = newUpdateTagModule })
                    in
                    ( { model | activePage = newTagPage }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DeleteTag ->
            case model.activePage of
                TagPage (Initialized a) ->
                    ( model
                    , deleteTag a.updateTagModule
                    )

                _ ->
                    ( model, Cmd.none )

        -- SEARCH PAGE --
        GotSearchInput searchKeyword ->
            let
                newPage =
                    case model.activePage of
                        TagPage (Initialized tagPage) ->
                            ContentSearchPage searchKeyword [] tagPage.tag.tagId

                        ContentSearchPage _ contentList tagIdToReturnItsPage ->
                            ContentSearchPage searchKeyword contentList tagIdToReturnItsPage

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
            ( newModel, Cmd.batch [ sendTitle newModel, getAllTagsCmdMsg, getSearchResult searchKeyword, Dom.focus "contentSearchInputInSearchPage" |> Task.attempt FocusResult ] )

        GotContentSearchResponse res ->
            case res of
                Ok gotContentSearchResponse ->
                    let
                        newPage =
                            case model.activePage of
                                ContentSearchPage searchKeyword _ tagIdToReturnItsPage ->
                                    ContentSearchPage searchKeyword (List.map (gotContentToContent model) gotContentSearchResponse.contents) tagIdToReturnItsPage

                                _ ->
                                    model.activePage
                    in
                    ( { model | activePage = newPage }, Cmd.none )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- UNDO --
        Undo ->
            case model.activePage of
                TagPage (Initialized _) ->
                    ( model
                    , undo
                    )

                _ ->
                    ( model, Cmd.none )

        UndoDoneResponse res ->
            case res of
                Ok _ ->
                    case model.activePage of
                        TagPage (Initialized a) ->
                            let
                                newModel =
                                    { model | allTags = [], activePage = TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput a.tag.tagId))) }
                            in
                            ( newModel, getCmdToSendByPage newModel )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        -- DRAG CONTENT --
        DragDoneResponse res ->
            case res of
                Ok _ ->
                    case model.activePage of
                        TagPage (Initialized a) ->
                            let
                                newModel =
                                    { model | allTags = [], activePage = TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput a.tag.tagId))) }
                            in
                            ( newModel, getCmdToSendByPage newModel )

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    createNewModelAndCmdMsg model NotFoundPage

        SetContentWhichCursorIsOverIt contentTagDuoWhichCursorIsOverItNow ->
            let
                idOfContentLine =
                    case contentTagDuoWhichCursorIsOverItNow of
                        Nothing ->
                            "this-will-never-happen"

                        Just contentTagIdDuoWithOffsetPosY ->
                            contentTagIdDuoWithOffsetPosY.contentId ++ contentTagIdDuoWithOffsetPosY.tagId
            in
            ( { model | contentTagDuoWhichCursorIsOverItNow = contentTagDuoWhichCursorIsOverItNow }, Task.attempt GotContentLineElementToGetItsHeight (Dom.getElement idOfContentLine) )

        SetContentTagIdDuoToDragAfterASecond contentTagDuo ->
            --this "a second delay" is for this: somehow, setting model.contentTagIdDuoThatIsBeingDragged to something prevents opening links on content lines (or more generally, it somehow overrides left click event and it happens on mouseDown event in TagTextView.elm. so, as a hacky solution, I give a time delay to perform "update model.contentTagIdDuoThatIsBeingDragged" task
            ( model
            , Process.sleep 200
                |> Task.perform (\_ -> SetContentTagIdDuoToDrag contentTagDuo)
            )

        SetContentTagIdDuoToDrag contentTagDuo ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        newActiveTagTextViewTypeAndQuickContentAdderCloseDecision =
                            case a.activeTagTextViewType of
                                DistinctGroupView ->
                                    ( GroupView, True )

                                other ->
                                    ( other, False )

                        newQuickContentAdderBoxStatus =
                            if second newActiveTagTextViewTypeAndQuickContentAdderCloseDecision then
                                NothingButTextToStore ""

                            else
                                a.quickContentAdderModule

                        newTagPage =
                            TagPage (Initialized { a | activeTagTextViewType = first newActiveTagTextViewTypeAndQuickContentAdderCloseDecision, quickContentAdderModule = newQuickContentAdderBoxStatus })

                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | tagTextViewType = first newActiveTagTextViewTypeAndQuickContentAdderCloseDecision }

                        newModel =
                            { model | localStorage = newLocalStorage, activePage = newTagPage, contentTagIdDuoThatIsBeingDragged = contentTagDuo }
                    in
                    ( newModel, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DragEnd _ ->
            case model.activePage of
                TagPage (Initialized tagPage) ->
                    case model.contentTagIdDuoThatIsBeingDragged of
                        Just toDrag ->
                            case model.contentTagDuoWhichCursorIsOverItNow of
                                Just toDropOn ->
                                    -- do not do anything in any situation if beingDraggedContent and theContentToDragTopOrBottom has the same contentId. just clear contentTagIdDuoThatIsBeingDragged
                                    if toDrag.contentId == toDropOn.contentId then
                                        ( { model | contentTagIdDuoThatIsBeingDragged = Nothing }, Cmd.none )

                                    else
                                        let
                                            droppedOnWhichSectionData =
                                                droppedOnWhichSection toDropOn.offsetPosY toDropOn.contentLineHeight
                                        in
                                        case droppedOnWhichSectionData of
                                            Middle ->
                                                ( { model | contentTagIdDuoThatIsBeingDragged = Nothing }, Cmd.none )

                                            topOrDown ->
                                                ( { model | contentTagIdDuoThatIsBeingDragged = Nothing }
                                                , dragContent
                                                    (DragContentRequestModel
                                                        tagPage.activeTagTextViewType
                                                        ( toDrag.contentId, toDrag.tagId )
                                                        ( toDropOn.contentId, toDropOn.tagId )
                                                        topOrDown
                                                        tagPage.tag.tagId
                                                    )
                                                )

                                Nothing ->
                                    ( { model | contentTagIdDuoThatIsBeingDragged = Nothing }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


droppedOnWhichSection : Float -> Float -> DropSection
droppedOnWhichSection float contentLineHeight =
    if float < topOffsetForContentLine contentLineHeight then
        Top

    else if float > downOffsetForContentLine contentLineHeight then
        Down

    else
        Middle


findNextLocationOfQuickContentAdder : List TagTextPart -> QuickContentAdderLocation -> TagTextViewType -> QuickContentAdderModel
findNextLocationOfQuickContentAdder tagTextParts prevQuickContentAdderLocation activeTagTextViewType =
    let
        maybeRelatedTagTextPart : Maybe TagTextPart
        maybeRelatedTagTextPart =
            case activeTagTextViewType of
                LineView ->
                    List.head tagTextParts

                _ ->
                    List.head (List.filter (\ttp -> ttp.tag.tagId == prevQuickContentAdderLocation.contentLineTagId) tagTextParts)

        result : QuickContentAdderModel
        result =
            case maybeRelatedTagTextPart of
                Nothing ->
                    -- not-existing path
                    NothingButTextToStore ""

                Just relatedTextPart ->
                    let
                        relatedContents =
                            relatedTextPart.contents

                        contentIdEquivalentOfRelatedTextPart : List String
                        contentIdEquivalentOfRelatedTextPart =
                            List.map (\c -> c.contentId) relatedContents

                        indexOfContentOnItsTagTextPart : Int
                        indexOfContentOnItsTagTextPart =
                            Maybe.withDefault -1 (List.Extra.elemIndex prevQuickContentAdderLocation.contentLineContentId contentIdEquivalentOfRelatedTextPart)

                        idToUse =
                            case prevQuickContentAdderLocation.locatedAt of
                                BeforeContentLine ->
                                    indexOfContentOnItsTagTextPart - 1

                                AfterContentLine ->
                                    indexOfContentOnItsTagTextPart

                        newPrevLineContent : Maybe Content
                        newPrevLineContent =
                            List.Extra.getAt idToUse relatedContents

                        newCurrentLineContent : Content
                        newCurrentLineContent =
                            Maybe.withDefault dummyContent (List.Extra.getAt (idToUse + 1) relatedContents)

                        newNextLineContent : Maybe Content
                        newNextLineContent =
                            List.Extra.getAt (idToUse + 2) relatedContents

                        newQuickContentAdderLocation : QuickContentAdderLocation
                        newQuickContentAdderLocation =
                            { contentLineContentId = newCurrentLineContent.contentId
                            , contentLineTagId = newCurrentLineContent.tagIdOfCurrentTextPart
                            , tagIdOfActiveTagPage = prevQuickContentAdderLocation.tagIdOfActiveTagPage
                            , locatedAt = prevQuickContentAdderLocation.locatedAt
                            , prevLineContentId = Maybe.map (\a -> a.contentId) newPrevLineContent
                            , nextLineContentId = Maybe.map (\a -> a.contentId) newNextLineContent
                            }
                    in
                    JustQuickContentAdderData newQuickContentAdderLocation ""
    in
    result


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onMouseUp (Decode.map (\event -> DragEnd ( setX event, setY event )) Mouse.eventDecoder)


setX : Event -> Float
setX event =
    first event.clientPos


setY : Event -> Float
setY event =
    second event.clientPos
