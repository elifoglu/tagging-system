module App.Model exposing (ContentIDToColorize, CreateContentPageModel, CreateTagPageModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, MaySendRequest(..), MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), UpdateContentPageData, UpdateContentPageModel(..), UpdateTagPageModel, createContentPageModelEncoder, createTagPageModelEncoder, getContentRequestModelEncoder, getTagContentsRequestModelEncoder, homepage, setCreateContentPageModel, setUpdateContentPageModel, updateContentPageDataEncoder, updateTagPageModelEncoder)

import Browser.Navigation as Nav
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, GotContent, GotTagTextPart)
import Json.Encode as Encode
import Tag.Model exposing (Tag)
import TagTextPart.Model exposing (TagTextPart)
import Time


type alias Model =
    { log : String
    , key : Nav.Key
    , allTags : List Tag
    , homeTagId : String
    , activePage : Page
    , localStorage : LocalStorage
    , waitingForContentCheckResponse : Bool
    , timeZone : Time.Zone
    }


type alias LocalStorage =
    {}


type alias ContentToAddToBottom =
    Maybe GotContent


type alias MaybeTextToHighlight =
    Maybe String


type alias IconInfo =
    { urlToNavigate : String
    , iconImageUrl : String
    , marginLeft : String
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
    { tagId : TagIdInputType
    }


type TagIdInputType
    = HomeInput
    | IdInput String


type alias InitializedTagPageModel =
    { tag : Tag
    , textParts : List TagTextPart
    }


type alias BlogTagsToShow =
    Maybe (List Tag)


type alias AllTagsToShow =
    Maybe (List Tag)


type alias ContentIDToColorize =
    Maybe ContentID


homepage : Page
homepage =
    TagPage (NonInitialized (NonInitializedYetTagPageModel HomeInput))


type Page
    = ContentPage (Initializable Int Content)
    | TagPage (Initializable NonInitializedYetTagPageModel InitializedTagPageModel)
    | CreateContentPage (MaySendRequest CreateContentPageModel CreateContentPageModel)
    | UpdateContentPage UpdateContentPageModel
    | CreateTagPage (MaySendRequest CreateTagPageModel CreateTagPageModel)
    | UpdateTagPage (MaySendRequest ( UpdateTagPageModel, String ) UpdateTagPageModel)
    | ContentSearchPage String (List Content)
    | NotFoundPage
    | MaintenancePage


type alias GetContentRequestModel =
    { contentID : Int
    }


type alias GetTagContentsRequestModel =
    { tagId : String
    }


type alias CreateContentPageModel =
    { maybeContentToPreview : Maybe Content
    , id : String
    , title : String
    , text : String
    , tags : String
    , contentIdToCopy : String
    }


type alias UpdateContentPageData =
    { contentId : ContentID
    , maybeContentToPreview : Maybe Content
    , title : String
    , text : String
    , tags : String
    }


type alias CreateTagPageModel =
    { tagId : String
    , name : String
    }


type alias UpdateTagPageModel =
    { infoContentId : String
    }


setCreateContentPageModel : Content -> CreateContentPageModel
setCreateContentPageModel content =
    { maybeContentToPreview = Just content
    , id = ""
    , title = Maybe.withDefault "" content.title
    , text = content.text
    , tags = String.join "," (List.map (\tag -> tag.name) content.tags)
    , contentIdToCopy = ""
    }


setUpdateContentPageModel : Content -> UpdateContentPageData
setUpdateContentPageModel content =
    { contentId = content.contentId
    , maybeContentToPreview = Just content
    , title = Maybe.withDefault "" content.title
    , text = content.text
    , tags = String.join "," (List.map (\tag -> tag.name) content.tags)
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
        ]


createContentPageModelEncoder : CreateContentPageModel -> Encode.Value
createContentPageModelEncoder model =
    Encode.object
        [ ( "id", Encode.string model.id )
        , ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
        ]


updateContentPageDataEncoder : ContentID -> UpdateContentPageData -> Encode.Value
updateContentPageDataEncoder contentId model =
    Encode.object
        [ ( "id", Encode.string (String.fromInt contentId) )
        , ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
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
