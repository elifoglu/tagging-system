module Component.Page.Util exposing (..)

import App.Model exposing (Initializable(..), InitializedTagPageModel, Model, Page(..))

tagsNotLoaded : Model -> Bool
tagsNotLoaded model =
    model.allTags == []
