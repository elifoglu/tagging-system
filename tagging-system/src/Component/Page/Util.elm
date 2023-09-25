module Component.Page.Util exposing (..)

import App.Model exposing (Initializable(..), InitializedTagPageModel, Model, Page(..))
import Tag.Model exposing (Tag)


flipBoolAndToStr : Bool -> String
flipBoolAndToStr bool =
    if bool == True then
        "false"

    else
        "true"


tagsNotLoaded : Model -> Bool
tagsNotLoaded model =
    model.allTags == []

-- this is just to reach InitializedTagPageModel easily

extractInitializedTagPageModel : Page -> Maybe InitializedTagPageModel
extractInitializedTagPageModel page =
        case page of
            TagPage initializable ->
                case initializable of
                    NonInitialized _ ->
                        Nothing

                    Initialized initializedTagPageModel ->
                        Just initializedTagPageModel
            _ -> Nothing