module Content.Util exposing (gotContentToContent, createdDateOf, lastModifiedDateOf)

import App.Model exposing (Model)
import Content.Model exposing (Content, ContentDate)
import DataResponse exposing (GotContent, GotContentDate, GotTag)
import Date exposing (format)
import Maybe.Extra exposing (values)
import Tag.Util exposing (tagById)
import Time


gotContentToContent : Model -> GotContent -> Content
gotContentToContent model gotContent =
    { title = gotContent.title
    , createdAt = gotContentDateToContentDate model.timeZone gotContent.createdAt
    , lastModifiedAt = gotContentDateToContentDate model.timeZone gotContent.lastModifiedAt
    , isDeleted = gotContent.isDeleted
    , contentId = gotContent.contentId
    , text = gotContent.content
    , tags =
        gotContent.tagIds
            |> List.map (tagById model.allTags)
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



createdDateOf : Content -> String
createdDateOf content =
    format "dd.MM.yy" content.createdAt

lastModifiedDateOf : Content -> String
lastModifiedDateOf content =
    format "dd.MM.yy" content.lastModifiedAt