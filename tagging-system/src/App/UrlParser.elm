module App.UrlParser exposing (pageBy)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, Initializable(..), LocalStorage, MaySendRequest(..), NonInitializedYetTagPageModel, Page(..), TagIdInputType(..), UpdateContentPageData, UpdateContentPageModel(..), UpdateTagPageModel, homepage)
import Url
import Url.Parser exposing ((</>), (<?>), Parser, int, map, oneOf, parse, s, string, top)
import Url.Parser.Query as Query


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map homepage top
        , map nonInitializedTagPageMapper (s "tags" </> string <?> Query.int "page")
        , map nonInitializedContentPageMapper (s "contents" </> int)
        , map (CreateContentPage (NoRequestSentYet (CreateContentPageModel Nothing "" "" "" "" ""))) (s "create" </> s "content")
        , map nonInitializedUpdateContentPageMapper (s "update" </> s "content" </> int)
        , map (CreateTagPage (NoRequestSentYet (CreateTagPageModel "" ""))) (s "create" </> s "tag")
        , map nonInitializedUpdateTagPageMapper (s "update" </> s "tag" </> string)
        ]


nonInitializedTagPageMapper : String -> Maybe Int -> Page
nonInitializedTagPageMapper tagId maybePage =
    TagPage (NonInitialized (NonInitializedYetTagPageModel (IdInput tagId) maybePage ))


nonInitializedContentPageMapper : Int -> Page
nonInitializedContentPageMapper contentId =
    ContentPage
        (NonInitialized  contentId)


nonInitializedUpdateContentPageMapper : Int -> Page
nonInitializedUpdateContentPageMapper contentId =
    UpdateContentPage (NotInitializedYet contentId)


nonInitializedUpdateTagPageMapper : String -> Page
nonInitializedUpdateTagPageMapper tagId =
    UpdateTagPage (NoRequestSentYet ( UpdateTagPageModel "", tagId ))


pageBy : Url.Url -> Page
pageBy url =
    Maybe.withDefault NotFoundPage <| parse routeParser url
