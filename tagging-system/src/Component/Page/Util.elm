module Component.Page.Util exposing (..)

import App.Model exposing (Model)
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