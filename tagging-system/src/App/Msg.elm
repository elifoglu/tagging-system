module App.Msg exposing (..)

import App.Model exposing (ContentTagIdDuo, ContentTagIdDuoWithOffsetPosY, LocatedAt, TagDeleteStrategyChoice, TagOption, TagTextViewType)
import Browser
import Browser.Dom as Dom
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, ContentSearchResponse, GotContent, InitialDataResponse, TagTextResponse, TagID)
import Http
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
    | GotTagOrContentCreateUpdateDeleteDoneResponse CrudAction (Result Http.Error String)
    | UndoDoneResponse (Result Http.Error String)
    | DragDoneResponse (Result Http.Error String)
    | SetContentTagIdDuoToDrag (Maybe ContentTagIdDuo)
    | SetContentWhichCursorIsOverIt (Maybe ContentTagIdDuoWithOffsetPosY)
    | ToggleCSAAdderBox ContentID TagID TagID LocatedAt (Maybe ContentID) (Maybe ContentID)
    | CSAAdderInputChanged String
    | OpenQuickContentEditInput Content
    | QuickContentEditInputChanged String
    | KeyDown KeyDownPlace Int
    | DragEnd ( Float, Float )
    | GotTimeZone Time.Zone
    | DoNothing

type KeyDownPlace =
    CSAAdderInput
    | QuickContentEditInput

type CrudAction =
    CreateContentAct
    | UpdateContentAct
    | DeleteContentAct
    | CreateTagAct
    | UpdateTagAct
    | DeleteTagAct
    | CreateContentActViaCSAAdder

type WorkingOnWhichModule
    = WorkingOnCreateTagModule
    | WorkingOnUpdateTagModule
    | WorkingOnCreateContentModule
    | WorkingOnUpdateContentModule

type ContentInputTypeForContentCreationOrUpdate
    = Title
    | Text


type TagInputType
    = Name String
    | Description String


type TagPickerInputType
    = SearchInput String
    | OptionClicked TagOption
    | OptionRemoved TagOption
