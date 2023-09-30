module App.Msg exposing (..)

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
    | UpdateTagModuleInputChanged TagInputType
    | CreateContent
    | ToggleCreateContentModule Bool
    | ToggleCreateTagModule Bool
    | UpdateContent
    | CreateTag
    | UpdateTag
    | GotTagUpdateOrCreationDoneResponse (Result Http.Error String)
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
    | InfoContentId String