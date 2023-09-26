module TagTextPart.Util exposing (toGotTagTextPartToTagTextPart)

import App.Model exposing (Model)
import Content.Util exposing (gotContentToContent)
import DataResponse exposing (GotTagTextPart)
import List
import TagTextPart.Model exposing (TagTextPart)


toGotTagTextPartToTagTextPart: Model -> GotTagTextPart -> TagTextPart
toGotTagTextPartToTagTextPart model gotTagTextPart =
    TagTextPart gotTagTextPart.tag (List.map (gotContentToContent model) gotTagTextPart.contents)