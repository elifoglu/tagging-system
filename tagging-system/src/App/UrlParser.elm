module App.UrlParser exposing (pageBy)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Initializable(..), LocalStorage,  NonInitializedYetTagPageModel, NonInitializedYetContentPageModel, Page(..), TagIdInputType(..), UpdateContentModuleModel, UpdateTagModuleModel, homepage)
import Url
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, string, top)


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map homepage top
        , map nonInitializedContentPageMapper (s "contents" </> string)
        , map nonInitializedTagPageMapper (s "tags" </> string)
        ]


nonInitializedTagPageMapper : String -> Page
nonInitializedTagPageMapper tagId =
    TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput tagId) ))


nonInitializedContentPageMapper : String -> Page
nonInitializedContentPageMapper contentId =
    ContentPage (NonInitialized (NonInitializedYetContentPageModel contentId ))



pageBy : Url.Url -> Page
pageBy url =
    Maybe.withDefault NotFoundPage <| parse routeParser url
