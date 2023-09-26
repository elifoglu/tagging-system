module Content.Util exposing (gotContentToContent, maybeDateText, maybeTagsOfContent)

import App.Model exposing (Model)
import Content.Model exposing (Content, ContentDate)
import DataResponse exposing (GotContent, GotContentDate, GotTag)
import Date exposing (format)
import Maybe.Extra exposing (values)
import Tag.Model exposing (Tag)
import Tag.Util exposing (tagNameToTag)
import Time


gotContentToContent : Model -> GotContent -> Content
gotContentToContent model gotContent =
    { title = gotContent.title
    , date = gotContentDateToContentDate model.timeZone gotContent.dateAsTimestamp
    , contentId = gotContent.contentId
    , text = gotContent.content
    , tags =
        gotContent.tags
            |> List.map (tagNameToTag model.allTags)
            |> values
    }


jan2000 =
    946688437314


gotContentDateToContentDate : Time.Zone -> GotContentDate -> ContentDate
gotContentDateToContentDate timeZone gotContentDate =
    case String.toInt gotContentDate of
        Just ms ->
            Date.fromPosix timeZone (Time.millisToPosix ms)

        Nothing ->
            Date.fromPosix timeZone (Time.millisToPosix jan2000)


contentHasTags : Content -> Bool
contentHasTags content =
    (content.tags
        |> List.length
    )
        > 0


maybeTagsOfContent : Content -> Maybe (List Tag)
maybeTagsOfContent content =
    case contentHasTags content of
        True ->
            Just content.tags

        False ->
            Nothing


maybeDateText : Content -> Maybe String
maybeDateText content =
    let
        dateText : String
        dateText =
            format "dd.MM.yy" content.date
    in
    Just dateText
