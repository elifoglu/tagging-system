module App.Msg exposing (..)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, Page, UpdateContentPageData, UpdateTagPageModel)
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
    | GotContentToPreviewForCreatePage CreateContentPageModel (Result Http.Error GotContent)
    | GotContentToPreviewForUpdatePage ContentID UpdateContentPageData (Result Http.Error GotContent)
    | ContentInputChanged ContentInputType String
    | TagInputChanged TagInputType
    | GetContentToCopyForContentCreation Int
    | PreviewContent PreviewContentModel
    | CreateContent CreateContentPageModel
    | UpdateContent ContentID UpdateContentPageData
    | CreateTag CreateTagPageModel
    | UpdateTag String UpdateTagPageModel
    | GotTagUpdateOrCreationDoneResponse (Result Http.Error String)
    | GotTimeZone Time.Zone


type PreviewContentModel
    = PreviewForContentCreate CreateContentPageModel
    | PreviewForContentUpdate ContentID UpdateContentPageData


type ContentInputType
    = Id
    | Title
    | Text
    | Tags
    | ContentToCopy


type TagInputType
    = TagId String
    | Name String
    | InfoContentId String