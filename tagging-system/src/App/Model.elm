module App.Model exposing (ContentIDToColorize, CreateContentModuleModel, CreateContentModule, CreateTagModuleModel, CreateTagModule, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, MaySendRequest(..), MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), UpdateContentModuleData, UpdateContentModuleModel(..), UpdateContentModule, UpdateTagModuleModel, UpdateTagModule, createContentPageModelEncoder, createTagRequestEncoder, defaultCreateContentModule, defaultCreateTagModule, defaultUpdateContentModule, defaultUpdateTagModule, getContentRequestModelEncoder, getTagContentsRequestModelEncoder, homepage, setUpdateContentPageModel, updateContentPageDataEncoder, updateTagPageModelEncoder)

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


homepage : Page
homepage =
    TagPage (NonInitialized (NonInitializedYetTagPageModel HomeInput))


type Page
    = ContentPage (Initializable Int Content)
    | TagPage (Initializable NonInitializedYetTagPageModel InitializedTagPageModel)
    | ContentSearchPage String (List Content)
    | NotFoundPage
    | MaintenancePage


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


type UpdateContentModuleModel
    = NotInitializedYet ContentID
    | GotContentToUpdate UpdateContentModuleData
    | UpdateRequestIsSent UpdateContentModuleData


type alias NonInitializedYetTagPageModel =
    { tagId : TagIdInputType
    }


type TagIdInputType
    = HomeInput
    | IdInput String


type alias InitializedTagPageModel =
    { tag : Tag
    , textParts : List TagTextPart
    , createContentModule : CreateContentModule
    , updateContentModule : UpdateContentModule
    , createTagModule : CreateTagModule
    , updateTagModule : UpdateTagModule
    }


defaultCreateContentModule =
    { isVisible = True
    , model = CreateContentModuleModel "" "" ""
    }


defaultUpdateContentModule =
    { isVisible = False
    , model = NotInitializedYet ""
    }


defaultCreateTagModule =
    { isVisible = True
    , model = CreateTagModuleModel ""
    }


defaultUpdateTagModule =
    { isVisible = False
    , model = UpdateTagModuleModel "" "" ""
    }


type alias CreateContentModule =
    { isVisible : Bool
    , model : CreateContentModuleModel
    }


type alias UpdateContentModule =
    { isVisible : Bool
    , model : UpdateContentModuleModel
    }


type alias CreateTagModule =
    { isVisible : Bool
    , model : CreateTagModuleModel
    }


type alias UpdateTagModule =
    { isVisible : Bool
    , model : UpdateTagModuleModel
    }


type alias BlogTagsToShow =
    Maybe (List Tag)


type alias AllTagsToShow =
    Maybe (List Tag)


type alias ContentIDToColorize =
    Maybe ContentID


type alias GetContentRequestModel =
    { contentID : Int
    }


type alias GetTagContentsRequestModel =
    { tagId : String
    }


type alias CreateContentModuleModel =
    { title : String
    , text : String
    , tags : String
    }


type alias UpdateContentModuleData =
    { contentId : ContentID
    , title : String
    , text : String
    , tags : String
    }


type alias CreateTagModuleModel =
    { name : String
    }


type alias UpdateTagModuleModel =
    { tagId : String
    , name : String
    , infoContentId : String
    }


setUpdateContentPageModel : Content -> UpdateContentModuleData
setUpdateContentPageModel content =
    { contentId = content.contentId
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


createContentPageModelEncoder : CreateContentModuleModel -> Encode.Value
createContentPageModelEncoder model =
    Encode.object
        [ ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
        ]


updateContentPageDataEncoder : ContentID -> UpdateContentModuleData -> Encode.Value
updateContentPageDataEncoder contentId model =
    Encode.object
        [ ( "id", Encode.string contentId )
        , ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.string model.tags )
        ]


createTagRequestEncoder : CreateTagModuleModel -> Encode.Value
createTagRequestEncoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        ]


updateTagPageModelEncoder : UpdateTagModuleModel -> Encode.Value
updateTagPageModelEncoder model =
    Encode.object
        [ ( "infoContentId", Encode.string model.infoContentId )
        ]
