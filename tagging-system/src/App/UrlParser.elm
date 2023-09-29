module App.UrlParser exposing (pageBy)

import App.Model exposing (CreateContentModuleModel, CreateTagModuleModel, Initializable(..), LocalStorage, MaySendRequest(..), NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), UpdateContentModuleData, UpdateContentModuleModel(..), UpdateTagModuleModel, homepage)
import Url
import Url.Parser exposing ((</>), (<?>), Parser, int, map, oneOf, parse, s, string, top)


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map homepage top
        , map nonInitializedTagPageMapper (s "tags" </> string)
        , map nonInitializedContentPageMapper (s "contents" </> int)
        ]


nonInitializedTagPageMapper : String -> Page
nonInitializedTagPageMapper tagId =
    TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput tagId) ))


nonInitializedContentPageMapper : Int -> Page
nonInitializedContentPageMapper contentId =
    ContentPage
        (NonInitialized  contentId)


pageBy : Url.Url -> Page
pageBy url =
    Maybe.withDefault NotFoundPage <| parse routeParser url
