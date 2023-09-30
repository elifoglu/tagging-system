module Tag.Util exposing (tagById, tagByIdForced)

import List
import Tag.Model exposing (Tag)


tagById : List Tag -> String -> Maybe Tag
tagById allTags tagId =
    allTags
        |> List.filter (\tag -> tag.tagId == tagId)
        |> List.head

tagByIdForced : List Tag -> String -> Tag
tagByIdForced allTags tagId =
    Maybe.withDefault (Tag "" "" [] [] 0 "") (tagById allTags tagId)