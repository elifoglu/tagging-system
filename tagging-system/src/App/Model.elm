module App.Model exposing (ContentIDToColorize, ContentModuleVisibility(..), CreateContentModuleModel, CreateTagModuleModel, GetContentRequestModel, GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), TagModuleVisibility(..), TagOption, TagPickerModuleModel, UpdateContentModuleModel, UpdateTagModuleModel, createContentRequestEncoder, createTagRequestEncoder, defaultCreateContentModule, defaultCreateTagModule, defaultUpdateContentModule, defaultUpdateTagModule, getContentRequestModelEncoder, getDataOfTagRequestModelEncoder, homepage, updateContentRequestEncoder, updateTagRequestEncoder, allTagOptions, selectedTagOptionsForTag, selectedTagOptionsForContent, TagDeleteStrategyChoice(..), deleteTagRequestEncoder)

import Browser.Navigation as Nav
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, GotContent, GotTagTextPart)
import Date exposing (fromPosix)
import Json.Encode as Encode
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
import TagTextPart.Model exposing (TagTextPart)
import Time exposing (millisToPosix, utc)


type alias Model =
    { log : String
    , key : Nav.Key
    , allTags : List Tag
    , homeTagId : String
    , undoable : Bool
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
    = TagPage (Initializable NonInitializedYetTagPageModel InitializedTagPageModel)
    | ContentSearchPage String (List Content)
    | NotFoundPage


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
    , createTagModule : CreateTagModuleModel
    , updateTagModule : UpdateTagModuleModel
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
    UpdateContentModuleModel dummyContent "" "" (TagPickerModuleModel "" [] [] Nothing)


dummyContent : Content
dummyContent =
       Content Nothing (fromPosix utc (millisToPosix 0))  (fromPosix utc (millisToPosix 0)) False "" "" []

defaultCreateTagModule : List Tag -> CreateTagModuleModel
defaultCreateTagModule allTags =
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


defaultUpdateTagModule : Tag -> List Tag -> UpdateTagModuleModel
defaultUpdateTagModule tagToUpdate allTags =
    UpdateTagModuleModel tagToUpdate.tagId tagToUpdate.name tagToUpdate.description (TagPickerModuleModel "" (allTagOptions allTags) (selectedTagOptionsForTag tagToUpdate allTags) (Just tagToUpdate.tagId)) DeleteTheTagOnly


selectedTagOptionsForTag : Tag -> List Tag -> List TagOption
selectedTagOptionsForTag tag allTags =
    let
        parentTagsOfTagToUpdate : List Tag
        parentTagsOfTagToUpdate =
            tag.parentTags
                |> List.map (tagByIdForced allTags)
    in
    allTags
        |> List.filter (\t -> List.member t parentTagsOfTagToUpdate)
        |> List.map tagToTagOption

selectedTagOptionsForContent : Content -> List Tag -> List TagOption
selectedTagOptionsForContent content allTags =
    allTags
        |> List.filter (\t -> List.member t content.tags)
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
    { content : Content
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
    , tagDeleteStrategy : TagDeleteStrategyChoice
    }

type TagDeleteStrategyChoice
    = DeleteTheTagOnly
    | DeleteTagAlongWithItsChildContents
    | DeleteTagAlongWithItsAllContents


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


updateTagRequestEncoder : UpdateTagModuleModel -> Encode.Value
updateTagRequestEncoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "description", Encode.string model.description )
        , ( "parentTags", Encode.list Encode.string (model.tagPickerModelForParentTags.selectedTagOptions |> List.map (\tagOption -> tagOption.tagId)) )
        ]

deleteTagRequestEncoder : UpdateTagModuleModel -> Encode.Value
deleteTagRequestEncoder model =
    Encode.object
        [ ( "tagDeletionStrategy", Encode.string (
                case model.tagDeleteStrategy of
                    DeleteTheTagOnly ->
                        "only-tag"

                    DeleteTagAlongWithItsChildContents ->
                        "tag-and-child-contents"

                    DeleteTagAlongWithItsAllContents ->
                        "tag-with-all-descendants"

         )
         )
        ]
