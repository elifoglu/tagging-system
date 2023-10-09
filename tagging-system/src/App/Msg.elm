module App.Msg exposing (..)

import App.Model exposing (ContentTagIdDuo, ContentTagIdDuoWithOffsetPosY, LocatedAt, TagDeleteStrategyChoice, TagOption, TagTextViewType, Theme)
import Browser
import Browser.Dom as Dom
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, ContentSearchResponse, GotContent, GotContentResponse, InitialDataResponse, TagID, TagTextResponse)
import Http
import ScrollTo
import Tag.Model exposing (Tag)
import Time
import Url


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | GotInitialDataResponse (Result Http.Error InitialDataResponse)
    | GotSearchInput String
    | GotContentSearchResponse (Result Http.Error ContentSearchResponse)
    | FocusResult (Result Dom.Error ())
    | GotTagTextOfTag Tag (Result Http.Error TagTextResponse)
    | GotContent (Result Http.Error GotContentResponse)
    | CreateContentModuleInputChanged ContentInputTypeForContentCreationOrUpdate String
    | UpdateContentModuleInputChanged ContentInputTypeForContentCreationOrUpdate String
    | CreateTagModuleInputChanged TagInputType
    | ToggleUpdateTagModuleVisibility
    | ToggleUpdateContentModuleFor Content
    | UpdateTagModuleInputChanged TagInputType
    | TagPickerModuleInputChanged WorkingOnWhichModule TagPickerInputType
    | CreateContent
    | UpdateContent
    | DeleteContent Content
    | CreateTag
    | UpdateTag
    | ChangeTagDeleteStrategySelection TagDeleteStrategyChoice
    | ChangeTagTextViewTypeSelection TagTextViewType
    | DeleteTag
    | Undo
    | ClearUndoStack
    | GotTagOrContentCreateUpdateDeleteDoneResponse CrudAction (Result Http.Error String)
    | UndoActionDoneResponse (Result Http.Error String)
    | DragDoneResponse (Result Http.Error String)
    | SetContentTagIdDuoToDragAfterASecond (Maybe ContentTagIdDuo)
    | SetContentTagIdDuoToDrag (Maybe ContentTagIdDuo)
    | SetContentWhichCursorIsOverIt (Maybe ContentTagIdDuoWithOffsetPosY)
    | ToggleQuickContentAdderBox ContentID TagID TagID LocatedAt (Maybe ContentID) (Maybe ContentID)
    | QuickContentAdderInputChanged String
    | OpenQuickContentEditInput Content
    | QuickContentEditInputChanged String
    | KeyDown KeyDownPlace KeyDownType
    | GotContentLineElementToGetItsHeight (Result Dom.Error Dom.Element)
    | DragEnd ( Float, Float )
    | ThemeChanged Theme
    | GotTimeZone Time.Zone
    | ScrollToMsg ScrollTo.Msg
    | DoNothing

type KeyDownPlace =
    QuickContentAdderInput
    | QuickContentEditInput
    | SearchInputOnSearchPage
    | TagPickerModuleInput WorkingOnWhichModule

type KeyDownType
    = Enter
    | ShiftEnter
    | Escape
    | OtherSoNoOp

type CrudAction =
    CreateContentAct
    | UpdateContentActOnTagPage
    | UpdateContentActOnContentPage
    | DeleteContentAct
    | CreateTagAct
    | UpdateTagAct
    | DeleteTagAct
    | CreateContentActViaQuickContentAdder
    | UpdateContentActViaQuickContentEditor

type WorkingOnWhichModule
    = WorkingOnCreateTagModule
    | WorkingOnUpdateTagModule
    | WorkingOnCreateContentModule
    | WorkingOnUpdateContentModule

type ContentInputTypeForContentCreationOrUpdate
    = Title
    | Text
    | AsADoc


type TagInputType
    = Name String
    | Description String


type TagPickerInputType
    = ToggleSelectionList
    | SearchInput String
    | OptionClicked TagOption
    | OptionRemoved TagOption
