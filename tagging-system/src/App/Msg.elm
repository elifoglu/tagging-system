module App.Msg exposing (..)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, Page, UpdateContentPageData, UpdateTagPageModel)
import Browser
import Browser.Dom as Dom
import Content.Model exposing (GotGraphData)
import DataResponse exposing (InitialDataResponse, ContentID, ContentSearchResponse, ContentsResponse, GotContent)
import Graph exposing (NodeId)
import Http
import Tag.Model exposing (Tag)
import Time
import Url


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | GotInitialDataResponse (Result Http.Error InitialDataResponse)
    | GotGraphData (Result Http.Error GotGraphData)
    | GotSearchInput String
    | GotContentSearchResponse (Result Http.Error ContentSearchResponse)
    | FocusResult (Result Dom.Error ())
    | GoToContentViaContentGraph ContentID Bool
    | ColorizeContentOnGraph ContentID
    | UncolorizeContentOnGraph
    | GotContentsOfTag Tag (Result Http.Error ContentsResponse)
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
    | DragStart NodeId ( Float, Float )
    | DragAt ( Float, Float )
    | DragEnd ( Float, Float )
    | Tick Time.Posix
    | GotTimeZone Time.Zone
    | DoNothing


type PreviewContentModel
    = PreviewForContentCreate CreateContentPageModel
    | PreviewForContentUpdate ContentID UpdateContentPageData


type ContentInputType
    = Id
    | Title
    | Text
    | Tags
    | Refs
    | ContentToCopy


type TagInputType
    = TagId String
    | Name String
    | InfoContentId String