module App.UrlParser exposing (pageBy)

import App.Model exposing (CreateContentPageModel, CreateTagPageModel, Initializable(..), LocalStorage, MaySendRequest(..), NonInitializedYetTagPageModel, Page(..), UpdateContentPageData, UpdateContentPageModel(..), UpdateTagPageModel)
import Url
import Url.Parser exposing ((</>), (<?>), Parser, int, map, oneOf, parse, s, string, top)
import Url.Parser.Query as Query


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map (HomePage Nothing Nothing) top
        , map nonInitializedTagPageMapper (s "tags" </> string <?> Query.int "page")
        , map nonInitializedContentPageMapper (s "contents" </> int <?> Query.string "graph")
        , map (CreateContentPage (NoRequestSentYet (CreateContentPageModel Nothing "" "" "" "" "" ""))) (s "create" </> s "content")
        , map nonInitializedUpdateContentPageMapper (s "update" </> s "content" </> int)
        , map (CreateTagPage (NoRequestSentYet (CreateTagPageModel "" ""))) (s "create" </> s "tag")
        , map nonInitializedUpdateTagPageMapper (s "update" </> s "tag" </> string)
        , map grafPageMapper (s "g")
        , map ustveriPageMapper (oneOf [(s "ustveri"), (s "%C3%BCstveri")])
        ]


nonInitializedTagPageMapper : String -> Maybe Int -> Page
nonInitializedTagPageMapper tagId maybePage =
    TagPage (NonInitialized (NonInitializedYetTagPageModel tagId maybePage ))


nonInitializedContentPageMapper : Int -> Maybe String -> Page
nonInitializedContentPageMapper contentId maybeGraphIsOn =
    ContentPage
        (NonInitialized
            ( contentId
            , case maybeGraphIsOn of
                Just "true" ->
                    True

                _ ->
                    False
            )
        )


nonInitializedUpdateContentPageMapper : Int -> Page
nonInitializedUpdateContentPageMapper contentId =
    UpdateContentPage (NotInitializedYet contentId)


nonInitializedUpdateTagPageMapper : String -> Page
nonInitializedUpdateTagPageMapper tagId =
    UpdateTagPage (NoRequestSentYet ( UpdateTagPageModel "", tagId ))


grafPageMapper : Page
grafPageMapper =
    GraphPage Nothing


ustveriPageMapper : Page
ustveriPageMapper =
    RedirectPage "üstveri"


pageBy : Url.Url -> Page
pageBy url =
    Maybe.withDefault NotFoundPage <| parse routeParser url
