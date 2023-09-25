module App.Model exposing (BioPageModel, ContentIDToColorize, CreateContentPageModel, CreateTagPageModel, Drag, Entity, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, MaySendRequest(..), MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), TotalPageCountRequestModel, UpdateContentPageData, UpdateContentPageModel(..), UpdateTagPageModel, createContentPageModelEncoder, createTagPageModelEncoder, getContentRequestModelEncoder, getTagContentsRequestModelEncoder, setCreateContentPageModel, setUpdateContentPageModel, totalPageCountRequestModelEncoder, updateContentPageDataEncoder, updateTagPageModelEncoder)

import BioGroup.Model exposing (BioGroup)
import BioItem.Model exposing (BioItem)
import Browser.Navigation as Nav
import Content.Model exposing (Content, GotGraphData, GraphData)
import DataResponse exposing (ContentID, EksiKonserveException, EksiKonserveTopic, GotContent)
import Force
import Graph exposing (Graph, NodeId)
import Json.Encode as Encode
import Pagination.Model exposing (Pagination)
import Tag.Model exposing (Tag)
import Time


type alias Model =
    { log : String
    , key : Nav.Key
    , allTags : List Tag
    , activePage : Page
    , localStorage : LocalStorage
    , waitingForContentCheckResponse : Bool
    , timeZone : Time.Zone
    }


type alias LocalStorage =
    {}


type alias OpacityLevel =
    Float


type alias ContentToAddToBottom =
    Maybe GotContent


type alias MaybeTextToHighlight =
    Maybe String


type alias IconInfo =
    { urlToNavigate : String
    , iconImageUrl : String
    , marginLeft : String
    }


type alias Entity =
    Force.Entity NodeId { value : String }


type alias Drag =
    { start : ( Float, Float )
    , current : ( Float, Float )
    , index : NodeId
    }


type Initializable a b
    = NonInitialized a
    | Initialized b


type MaySendRequest pageData requestSentData
    = NoRequestSentYet pageData
    | RequestSent requestSentData


type UpdateContentPageModel
    = NotInitializedYet ContentID
    | GotContentToUpdate UpdateContentPageData
    | UpdateRequestIsSent UpdateContentPageData


type alias NonInitializedYetTagPageModel =
    { tagId : String
    , maybePage : Maybe Int
    }


type alias InitializedTagPageModel =
    { tag : Tag
    , contents : List Content
    , pagination : Pagination
    }


type alias BlogTagsToShow =
    Maybe (List Tag)


type alias AllTagsToShow =
    Maybe (List Tag)


type alias ContentIDToColorize =
    Maybe ContentID


type Page
    = HomePage AllTagsToShow (Maybe GraphData)
    | ContentPage (Initializable ( Int, Bool ) Content)
    | TagPage (Initializable NonInitializedYetTagPageModel InitializedTagPageModel)
    | CreateContentPage (MaySendRequest CreateContentPageModel CreateContentPageModel)
    | UpdateContentPage UpdateContentPageModel
    | CreateTagPage (MaySendRequest CreateTagPageModel CreateTagPageModel)
    | UpdateTagPage (MaySendRequest ( UpdateTagPageModel, String ) UpdateTagPageModel)
    | ContentSearchPage String (List Content)
    | GraphPage (Maybe GraphData)
    | RedirectPage String
    | NotFoundPage
    | MaintenancePage


type alias GetContentRequestModel =
    { contentID : Int
    }


type alias GetTagContentsRequestModel =
    { tagId : String
    , page : Maybe Int
    }


type alias TotalPageCountRequestModel =
    { tagId : String
    }


type alias CreateContentPageModel =
    { maybeContentToPreview : Maybe Content
    , id : String
    , title : String
    , text : String
    , tags : String
    , refs : String
    , contentIdToCopy : String
    }


type alias UpdateContentPageData =
    { contentId : ContentID
    , maybeContentToPreview : Maybe Content
    , title : String
    , text : String
    , tags : String
    , refs : String
    }


type alias CreateTagPageModel =
    { tagId : String
    , name : String
    }


type alias UpdateTagPageModel =
    { infoContentId : String
    }


type alias BioPageModel =
    { bioGroups : List BioGroup
    , bioItems : List BioItem
    , bioItemToShowInfo : Maybe BioItem
    }


setCreateContentPageModel : Content -> CreateContentPageModel
setCreateContentPageModel content =
    { maybeContentToPreview = Just content
    , id = ""
    , title = Maybe.withDefault "" content.title
    , text = content.text
    , tags = String.join "," (List.map (\tag -> tag.name) content.tags)
    , refs = String.join "," (List.map (\ref -> ref.id) content.refs)
    , contentIdToCopy = ""
    }


setUpdateContentPageModel : Content -> UpdateContentPageData
setUpdateContentPageModel content =
    { contentId = content.contentId
    , maybeContentToPreview = Just content
    , title = Maybe.withDefault "" content.title
    , text = content.text
    , tags = String.join "," (List.map (\tag -> tag.name) content.tags)
    , refs = String.join "," (List.map (\ref -> ref.id) content.refs)
    }


getContentRequestModelEncoder : GetContentRequestModel -> Encode.Value
getContentRequestModelEncoder model =
    Encode.object
        [ ( "contentID", Encode.string (String.fromInt model.contentID) )
        ]


getTagContentsRequestModelEncoder : GetTagContentsRequestModel -> Encode.Value
getTagContentsRequestModelEncoder model =
    Encode.object
        [ ( "tagId", Encode.string model.tagId )
        , ( "page"
          , case model.page of
                Just page ->
                    Encode.int page

                Nothing ->
                    Encode.int 1
          )
        ]


totalPageCountRequestModelEncoder : TotalPageCountRequestModel -> Encode.Value
totalPageCountRequestModelEncoder model =
    Encode.object
        [ ( "tagId", Encode.string model.tagId )
        ]


createContentPageModelEncoder : CreateContentPageModel -> Encode.Value
createContentPageModelEncoder model =
    Encode.object
        [ ( "id", Encode.string model.id )
        , ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
        , ( "refs", Encode.string model.refs )
        ]


updateContentPageDataEncoder : ContentID -> UpdateContentPageData -> Encode.Value
updateContentPageDataEncoder contentId model =
    Encode.object
        [ ( "id", Encode.string (String.fromInt contentId) )
        , ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
        , ( "refs", Encode.string model.refs )
        ]


createTagPageModelEncoder : CreateTagPageModel -> Encode.Value
createTagPageModelEncoder model =
    Encode.object
        [ ( "tagId", Encode.string model.tagId )
        , ( "name", Encode.string model.name )
        ]


updateTagPageModelEncoder : UpdateTagPageModel -> Encode.Value
updateTagPageModelEncoder model =
    Encode.object
        [ ( "infoContentId", Encode.string model.infoContentId )
        ]
