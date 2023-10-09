module App.Model exposing (ContentIDToColorize, ContentModuleVisibility(..), ContentTagIdDuo, ContentTagIdDuoWithOffsetPosY, CreateContentModuleModel, CreateTagModuleModel, DragContentRequestModel, DropSection(..), GetTagContentsRequestModel, IconInfo, Initializable(..), InitializedTagPageModel, LocalStorage, LocatedAt(..), MaybeTextToHighlight, Model, NonInitializedYetTagPageModel, Page(..), QuickContentAdderLocation, QuickContentAdderModel(..), QuickContentEditModel(..), TagDeleteStrategyChoice(..), TagIdInputType(..), TagModuleVisibility(..), TagOption, TagPickerModuleModel, TagTextViewType(..), Theme(..), UpdateContentModuleModel, UpdateTagModuleModel, allTagOptions, createContentRequestEncoder, createTagRequestEncoder, defaultCreateContentModule, defaultCreateTagModule, defaultUpdateContentModule, defaultUpdateTagModule, deleteTagRequestEncoder, downOffsetForContentLine, dragContentRequestEncoder, dummyContent, getDataOfTagRequestModelEncoder, homepage, requestEncoderForContentUpdateViaQuickContentEditBox, selectedTagOptionsForContent, selectedTagOptionsForTag, topOffsetForContentLine, updateContentRequestEncoder, updateTagRequestEncoder, NonInitializedYetContentPageModel, InitializedContentPageModel, GetContentRequestModel, getContentRequestModelEncoder, IDToReturnItsPage(..))

import Browser.Navigation as Nav
import Content.Model exposing (Content)
import DataResponse exposing (ContentID, GotContent, GotTagTextPart, TagID)
import Date exposing (fromPosix)
import Json.Encode as Encode
import ScrollTo
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagByIdForced)
import TagTextPart.Model exposing (TagTextPart)
import Time exposing (millisToPosix, utc)
import Tuple exposing (first, second)


type alias Model =
    { log : String
    , key : Nav.Key
    , allTags : List Tag
    , homeTagId : String
    , undoable : Bool
    , contentTagIdDuoThatIsBeingDragged : Maybe ContentTagIdDuo
    , contentTagDuoWhichCursorIsOverItNow : Maybe ContentTagIdDuoWithOffsetPosY
    , activePage : Page
    , localStorage : LocalStorage
    , timeZone : Time.Zone
    , previousQuickContentAdderLocationToKeepOpenAfterEnter : Maybe QuickContentAdderLocation
    , activeTheme : Theme
    , scrollTo: ScrollTo.State
    }


type Theme
    = Light
    | Dark


type alias ContentTagIdDuoWithOffsetPosY =
    { contentId : ContentID
    , tagId : TagID
    , offsetPosY : Float
    , contentLineHeight : Float
    }


type alias ContentTagIdDuo =
    { contentId : ContentID
    , tagId : TagID
    }


type alias LocalStorage =
    { activeTheme : Theme
    , tagTextViewType : TagTextViewType
    }


homepage : Page
homepage =
    TagPage (NonInitialized (NonInitializedYetTagPageModel HomeInput))


type Page
    = TagPage (Initializable NonInitializedYetTagPageModel InitializedTagPageModel)
    | ContentPage (Initializable NonInitializedYetContentPageModel InitializedContentPageModel)
    | ContentSearchPage String (List Content) IDToReturnItsPage
    | NotFoundPage


type IDToReturnItsPage =
    ReturnToTagPage TagID
    | ReturnToContentPage ContentID


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


type alias NonInitializedYetContentPageModel =
    { contentId : ContentID
    }


type TagIdInputType
    = HomeInput
    | IdInput String


type alias InitializedTagPageModel =
    { tag : Tag
    , textPartsForLineView : List TagTextPart
    , textPartsForGroupView : List TagTextPart
    , textPartsForDistinctGroupView : List TagTextPart
    , activeTagTextViewType : TagTextViewType
    , createContentModule : CreateContentModuleModel
    , updateContentModule : UpdateContentModuleModel
    , createTagModule : CreateTagModuleModel
    , updateTagModule : UpdateTagModuleModel
    , oneOfContentModuleIsVisible : ContentModuleVisibility
    , oneOfTagModuleIsVisible : TagModuleVisibility
    , quickContentAdderModule : QuickContentAdderModel
    , quickContentEditModule : QuickContentEditModel
    }


type alias InitializedContentPageModel =
    { content : Content
    }


type QuickContentEditModel
    = Open Content String
    | ClosedButTextToStore Content String


type QuickContentAdderModel
    = JustQuickContentAdderData QuickContentAdderLocation String
    | NothingButTextToStore String


type alias QuickContentAdderLocation =
    { contentLineContentId : String
    , contentLineTagId : String
    , tagIdOfActiveTagPage : String
    , locatedAt : LocatedAt
    , prevLineContentId : Maybe String
    , nextLineContentId : Maybe String
    }


type LocatedAt
    = BeforeContentLine
    | AfterContentLine


type TagTextViewType
    = LineView
    | GroupView
    | DistinctGroupView


type alias ViewContentsDistinct =
    Bool


type TagModuleVisibility
    = CreateTagModuleIsVisible
    | UpdateTagModuleIsVisible


type ContentModuleVisibility
    = CreateContentModuleIsVisible
    | UpdateContentModuleIsVisible


topOffsetForContentLine : Float -> Float
topOffsetForContentLine contentLineHeight =
    contentLineHeight / 100 * 17


downOffsetForContentLine : Float -> Float
downOffsetForContentLine contentLineHeight =
    contentLineHeight - topOffsetForContentLine contentLineHeight


defaultCreateContentModule : Tag -> List Tag -> CreateContentModuleModel
defaultCreateContentModule currentTag allTags =
    CreateContentModuleModel "" "" (TagPickerModuleModel "" (allTagOptions allTags) False [ tagToTagOption currentTag ] Nothing)


defaultUpdateContentModule : UpdateContentModuleModel
defaultUpdateContentModule =
    UpdateContentModuleModel dummyContent "" "" (TagPickerModuleModel "" [] False [] Nothing)


dummyContent : Content
dummyContent =
    Content Nothing (fromPosix utc (millisToPosix 0)) (fromPosix utc (millisToPosix 0)) False "" "" [] ""


defaultCreateTagModule : List Tag -> CreateTagModuleModel
defaultCreateTagModule allTags =
    CreateTagModuleModel "" "" (TagPickerModuleModel "" (allTagOptions allTags) False [] Nothing)


type alias TagPickerModuleModel =
    { input : String
    , allAvailableTagOptions : List TagOption
    , showTagOptionList : Bool
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
    UpdateTagModuleModel tagToUpdate.tagId tagToUpdate.name tagToUpdate.description (TagPickerModuleModel "" (allTagOptions allTags) False (selectedTagOptionsForTag tagToUpdate allTags) (Just tagToUpdate.tagId)) DeleteTheTagOnly


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


type alias GetTagContentsRequestModel =
    { tagId : String
    }

type alias GetContentRequestModel =
    { contentId : String
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


type alias DragContentRequestModel =
    { tagTextViewType : TagTextViewType
    , draggedContentTagIdDuo : ( String, String )
    , toDroppedOnContentTagIdDuo : ( String, String )
    , dropToFrontOfContent : DropSection
    , idOfActiveTagPage : String
    }


type DropSection
    = Top
    | Middle
    | Down


getDataOfTagRequestModelEncoder : GetTagContentsRequestModel -> Encode.Value
getDataOfTagRequestModelEncoder model =
    Encode.object
        [ ( "tagId", Encode.string model.tagId )
        ]


getContentRequestModelEncoder : GetContentRequestModel -> Encode.Value
getContentRequestModelEncoder model =
    Encode.object
        [ ( "contentId", Encode.string model.contentId )
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


requestEncoderForContentUpdateViaQuickContentEditBox : Content -> String -> Encode.Value
requestEncoderForContentUpdateViaQuickContentEditBox content updatedText =
    Encode.object
        [ ( "title", Encode.string (Maybe.withDefault "" content.title) )
        , ( "text", Encode.string updatedText )
        , ( "tags", Encode.list Encode.string (content.tags |> List.map (\t -> t.tagId)) )
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
        [ ( "tagDeletionStrategy"
          , Encode.string
                (case model.tagDeleteStrategy of
                    DeleteTheTagOnly ->
                        "only-tag"

                    DeleteTagAlongWithItsChildContents ->
                        "tag-and-child-contents"

                    DeleteTagAlongWithItsAllContents ->
                        "tag-with-all-descendants"
                )
          )
        ]


dragContentRequestEncoder : DragContentRequestModel -> Encode.Value
dragContentRequestEncoder model =
    Encode.object
        [ ( "tagTextViewType"
          , Encode.string
                (case model.tagTextViewType of
                    LineView ->
                        "line"

                    GroupView ->
                        "group"

                    DistinctGroupView ->
                        "distinct-group"
                )
          )
        , ( "idOfDraggedContent", Encode.string (first model.draggedContentTagIdDuo) )
        , ( "idOfTagGroupThatDraggedContentBelong", Encode.string (second model.draggedContentTagIdDuo) )
        , ( "idOfContentToDropOn", Encode.string (first model.toDroppedOnContentTagIdDuo) )
        , ( "idOfTagGroupToDropOn", Encode.string (second model.toDroppedOnContentTagIdDuo) )
        , ( "dropToFrontOrBack"
          , Encode.string
                (case model.dropToFrontOfContent of
                    Top ->
                        "front"

                    Down ->
                        "back"

                    Middle ->
                        "not-existing-path"
                )
          )
        , ( "idOfActiveTagPage", Encode.string model.idOfActiveTagPage )
        ]
