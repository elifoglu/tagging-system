module Main exposing (main)

import App.Model exposing (..)
import App.Msg exposing (ContentInputTypeForContentCreationOrUpdate(..), CrudAction(..), Msg(..), TagInputType(..), TagPickerInputType(..), WorkingOnWhichModule(..))
import App.Ports exposing (sendTitle, storeTagTextViewType)
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
import Requests exposing (createContent, createTag, deleteContent, deleteTag, dragContent, getInitialData, getSearchResult, getTagContents, getTimeZone, undo, updateContent, updateTag)
import Tag.Util exposing (tagById)
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


init : { tagTextViewType : Maybe String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
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

        model =
            Model "log" key [] "" False Nothing Nothing page (LocalStorage tagTextViewType) False Time.utc
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
        GotDataOfTag tag result ->
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

                                        newPage =
                                            TagPage <|
                                                Initialized (InitializedTagPageModel tag tagTextPartsForLineView tagTextPartsForGroupView tagTextPartsForDistinctGroupView model.localStorage.tagTextViewType (defaultCreateContentModule tag model.allTags) defaultUpdateContentModule (defaultCreateTagModule model.allTags) (defaultUpdateTagModule tag model.allTags) CreateContentModuleIsVisible CreateTagModuleIsVisible (NothingButTextToStore ""))

                                        newModel =
                                            { model | activePage = newPage }
                                    in
                                    ( newModel, getCmdToSendByPage newModel )

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
                            TagPage (Initialized { a | activeTagTextViewType = selection })

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
                    , if a.createContentModule.text == "" then
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
                    , if a.updateContentModule.text == "" then
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
                            , tagPickerModelForTags = TagPickerModuleModel "" (allTagOptions model.allTags) (selectedTagOptionsForContent c model.allTags) Nothing
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

        ToggleCSAAdderBox contentId tagId locatedAt prevLineContentId nextLineContentId ->
                case model.activePage of
                    TagPage (Initialized tagPage) ->
                        let
                            currentCSABoxModuleModel =
                                tagPage.csaBoxModule

                            newCSABoxModuleModelWithFocusMsg : (CSABoxModuleModel, Cmd Msg)
                            newCSABoxModuleModelWithFocusMsg = case currentCSABoxModuleModel of
                                JustCSABoxModuleData boxLocation text ->
                                    if boxLocation == CSABoxLocation contentId tagId locatedAt prevLineContentId nextLineContentId then
                                        (NothingButTextToStore text, Cmd.none)
                                    else
                                        (JustCSABoxModuleData (CSABoxLocation contentId tagId locatedAt prevLineContentId nextLineContentId) text, Dom.focus "csaAdderBox" |> Task.attempt FocusResult)

                                NothingButTextToStore textToStore ->
                                    (JustCSABoxModuleData (CSABoxLocation contentId tagId locatedAt prevLineContentId nextLineContentId) textToStore, Dom.focus "csaAdderBox" |> Task.attempt FocusResult)


                            newTagPage =
                                TagPage (Initialized { tagPage | csaBoxModule = first newCSABoxModuleModelWithFocusMsg })
                        in
                        ( { model | activePage = newTagPage }, second newCSABoxModuleModelWithFocusMsg )

                    _ ->
                        createNewModelAndCmdMsg model NotFoundPage

        CSAAdderInputChanged text ->
                case model.activePage of
                    TagPage (Initialized tagPage) ->
                        let
                            currentCSABoxModuleModel =
                                tagPage.csaBoxModule

                            newCSABoxModuleModel = case currentCSABoxModuleModel of
                                JustCSABoxModuleData boxLocation _ ->
                                    JustCSABoxModuleData boxLocation text

                                NothingButTextToStore textToStore ->
                                    NothingButTextToStore textToStore


                            newTagPage =
                                TagPage (Initialized { tagPage | csaBoxModule = newCSABoxModuleModel })
                        in
                        ( { model | activePage = newTagPage }, Cmd.none )

                    _ ->
                        createNewModelAndCmdMsg model NotFoundPage


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
                    createNewModelAndCmdMsg model NotFoundPage

        -- UNDO --
        Undo ->
            case model.activePage of
                TagPage (Initialized a) ->
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
            ( { model | contentTagDuoWhichCursorIsOverItNow = contentTagDuoWhichCursorIsOverItNow }, Cmd.none )

        SetContentTagIdDuoToDrag contentTagDuo ->
            case model.activePage of
                TagPage (Initialized a) ->
                    let
                        activeTagTextViewType =
                            case a.activeTagTextViewType of
                                DistinctGroupView ->
                                    GroupView

                                other ->
                                    other

                        newTagPage =
                            TagPage (Initialized { a | activeTagTextViewType = activeTagTextViewType })

                        localStorage =
                            model.localStorage

                        newLocalStorage =
                            { localStorage | tagTextViewType = activeTagTextViewType }

                        newModel =
                            { model | localStorage = newLocalStorage, activePage = newTagPage, contentTagIdDuoThatIsBeingDragged = contentTagDuo }
                    in
                    ( newModel, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DragEnd xy ->
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
                                            abc =
                                                droppedOnWhichSection toDropOn.offsetPosY
                                        in
                                        case abc of
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


droppedOnWhichSection : Float -> DropSection
droppedOnWhichSection float =
    if float < topOffsetForContentLine then
        Top

    else if float > downOffsetForContentLine then
        Down

    else
        Middle


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onMouseUp (Decode.map (\event -> DragEnd ( setX event, setY event )) Mouse.eventDecoder)


setX : Event -> Float
setX event =
    first event.clientPos


setY : Event -> Float
setY event =
    second event.clientPos
