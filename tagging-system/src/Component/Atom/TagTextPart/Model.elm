module TagTextPart.Model exposing (TagTextPart)

import Content.Model exposing (Content)
import Tag.Model exposing (Tag)

type alias TagTextPart =
    { tag : Tag
    , contents : List Content }
