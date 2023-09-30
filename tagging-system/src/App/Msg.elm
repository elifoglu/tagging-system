module App.Msg exposing (..)

import App.Model exposing (TagOption)
import Browser
import Browser.Dom as Dom
import DataResponse exposing (InitialDataResponse, ContentID, ContentSearchResponse, TagDataResponse, GotContent)
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
    | GotDataOfTag Tag (Result Http.Error TagDataResponse)
    | GotContent (Result Http.Error GotContent)
    | GotContentUpdateResponse (Result Http.Error GotContent)
    | GotContentCreationResponse (Result Http.Error GotContent)
    | CreateContentModuleInputChanged ContentInputTypeForContentCreation String
    | UpdateContentModuleInputChanged ContentInputTypeForContentUpdate String
    | CreateTagModuleInputChanged TagInputType
    | ToggleUpdateTagModuleVisibility
    | UpdateTagModuleInputChanged TagInputType
    | TagPickerModuleInputChanged TagPickerInputType
    | CreateContent
    | UpdateContent
    | CreateTag
    | UpdateTag
    | GotTagCreateUpdateDeleteDoneResponse (Result Http.Error String)
    | GotTimeZone Time.Zone


type ContentInputTypeForContentCreation
    = Title
    | Text
    | Tags


type ContentInputTypeForContentUpdate
    = TitleU
    | TextU
    | TagsU

type TagInputType
    = Name String
    | Description String

type TagPickerInputType
    = SearchInput String
    | OptionClicked TagOption
    | OptionRemoved TagOption
