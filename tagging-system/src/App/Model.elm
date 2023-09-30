module App.Model exposing (ContentIDToColorize, ContentModuleVisibility(..), CreateContentModuleModel, CreateTagModuleModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, MaySendRequest(..), MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), TagModuleVisibility(..), TagOption, TagPickerModuleModel, UpdateContentModuleModel, UpdateTagModuleModel, createContentRequestEncoder, createTagRequestEncoder, defaultCreateContentModule, defaultCreateTagModuleModel, defaultUpdateContentModule, defaultUpdateTagModuleModel, getContentRequestModelEncoder, getDataOfTagRequestModelEncoder, homepage, updateContentRequestEncoder, updateTagPageModelEncoder)

import Browser.Navigation as Nav
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, GotContent, GotTagTextPart)
import Json.Encode as Encode
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
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
    = ContentPage (Initializable String Content)
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



{-

   type UpdateContentModuleBaseModel
       = NotInitializedYet ContentID
       | GotContentToUpdate UpdateContentModuleData
       | UpdateRequestIsSent UpdateContentModuleData

-}


type alias NonInitializedYetTagPageModel =
    { tagId : TagIdInputType
    }


type TagIdInputType
    = HomeInput
    | IdInput String


type alias InitializedTagPageModel =
    { tag : Tag
    , textParts : List TagTextPart
    , createContentModule : CreateContentModuleModel
    , updateContentModule : UpdateContentModuleModel
    , createTagModuleModel : CreateTagModuleModel
    , updateTagModuleModel : UpdateTagModuleModel
    , oneOfContentModuleIsVisible : ContentModuleVisibility
    , oneOfTagModuleIsVisible : TagModuleVisibility
    }


type TagModuleVisibility
    = CreateTagModuleIsVisible
    | UpdateTagModuleIsVisible


type ContentModuleVisibility
    = CreateContentModuleIsVisible
    | UpdateContentModuleIsVisible


defaultCreateContentModule : List Tag -> CreateContentModuleModel
defaultCreateContentModule allTags =
    CreateContentModuleModel "" "" (TagPickerModuleModel "" (allTagOptions allTags) [] Nothing)


defaultUpdateContentModule : UpdateContentModuleModel
defaultUpdateContentModule =
    UpdateContentModuleModel "" "" "" (TagPickerModuleModel "" [] [] Nothing)


defaultCreateTagModuleModel : List Tag -> CreateTagModuleModel
defaultCreateTagModuleModel allTags =
    CreateTagModuleModel "" "" (TagPickerModuleModel "" (allTagOptions allTags) [] Nothing)


type alias TagPickerModuleModel =
    { input : String
    , allAvailableTagOptions : List TagOption
    , selectedTagOptions : List TagOption
    , tagIdToFilterOut : Maybe String
    }


type alias TagOption =
    { tagId : String
    , tagName : String
    }


allTagOptions : List Tag -> List TagOption
allTagOptions allTags =
    allTags
        |> List.map tagToTagOption


tagToTagOption : Tag -> TagOption
tagToTagOption tag =
    TagOption tag.tagId tag.name


defaultUpdateTagModuleModel : Tag -> List Tag -> UpdateTagModuleModel
defaultUpdateTagModuleModel tagToUpdate allTags =
    UpdateTagModuleModel tagToUpdate.tagId tagToUpdate.name tagToUpdate.description (TagPickerModuleModel "" (allTagOptions allTags) (selectedTagOptions tagToUpdate allTags) (Just tagToUpdate.tagId))


selectedTagOptions : Tag -> List Tag -> List TagOption
selectedTagOptions tag allTags =
    let
        parentTagsOfTagToUpdate : List Tag
        parentTagsOfTagToUpdate =
            tag.parentTags
                |> List.map (tagByIdForced allTags)
    in
    allTags
        |> List.filter (\t -> List.member t parentTagsOfTagToUpdate)
        |> List.map tagToTagOption


type alias BlogTagsToShow =
    Maybe (List Tag)


type alias AllTagsToShow =
    Maybe (List Tag)


type alias ContentIDToColorize =
    Maybe ContentID


type alias GetContentRequestModel =
    { contentID : String
    }


type alias GetTagContentsRequestModel =
    { tagId : String
    }


type alias CreateContentModuleModel =
    { title : String
    , text : String
    , tagPickerModelForTags : TagPickerModuleModel
    }


type alias UpdateContentModuleModel =
    { contentId : ContentID
    , title : String
    , text : String
    , tagPickerModelForTags : TagPickerModuleModel
    }


type alias CreateTagModuleModel =
    { name : String
    , description : String
    , tagPickerModelForParentTags : TagPickerModuleModel
    }


type alias UpdateTagModuleModel =
    { tagId : String
    , name : String
    , description : String
    , tagPickerModelForParentTags : TagPickerModuleModel
    }


getContentRequestModelEncoder : GetContentRequestModel -> Encode.Value
getContentRequestModelEncoder model =
    Encode.object
        [ ( "contentID", Encode.string model.contentID )
        ]


getDataOfTagRequestModelEncoder : GetTagContentsRequestModel -> Encode.Value
getDataOfTagRequestModelEncoder model =
    Encode.object
        [ ( "tagId", Encode.string model.tagId )
        ]


createContentRequestEncoder : CreateContentModuleModel -> Encode.Value
createContentRequestEncoder model =
    Encode.object
        [ ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.list Encode.string (model.tagPickerModelForTags.selectedTagOptions |> List.map (\tagOption -> tagOption.tagId)) )
        ]


updateContentRequestEncoder : UpdateContentModuleModel -> Encode.Value
updateContentRequestEncoder model =
    Encode.object
        [ ( "title", Encode.string model.title )
        , ( "text", Encode.string model.text )
        , ( "tags", Encode.list Encode.string (model.tagPickerModelForTags.selectedTagOptions |> List.map (\tagOption -> tagOption.tagId)) )
        ]


createTagRequestEncoder : CreateTagModuleModel -> Encode.Value
createTagRequestEncoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "description", Encode.string model.description )
        , ( "parentTags", Encode.list Encode.string (model.tagPickerModelForParentTags.selectedTagOptions |> List.map (\tagOption -> tagOption.tagId)) )
        ]


updateTagPageModelEncoder : UpdateTagModuleModel -> Encode.Value
updateTagPageModelEncoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "description", Encode.string model.description )
        , ( "parentTags", Encode.list Encode.string (model.tagPickerModelForParentTags.selectedTagOptions |> List.map (\tagOption -> tagOption.tagId)) )
        ]
