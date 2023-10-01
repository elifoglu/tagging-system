module App.UrlParser exposing (pageBy)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Initializable(..), LocalStorage,  NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), UpdateContentModuleModel, UpdateTagModuleModel, homepage)
import Url
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, string, top)


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map homepage top
        , map nonInitializedTagPageMapper (s "tags" </> string)
        ]


nonInitializedTagPageMapper : String -> Page
nonInitializedTagPageMapper tagId =
    TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput tagId) ))



pageBy : Url.Url -> Page
pageBy url =
    Maybe.withDefault NotFoundPage <| parse routeParser url
