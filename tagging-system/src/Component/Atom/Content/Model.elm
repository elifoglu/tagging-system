module Content.Model exposing (Content, ContentDate, GotGraphData, GraphData, Ref, RefConnection)

import App.GraphModel exposing (GraphModel)
import Date exposing (Date)
import Tag.Model exposing (Tag)


type alias Content =
    { title : Maybe String, date : ContentDate, contentId : ContentID, text : String, tags : List Tag, refs : List Ref, furtherReadingRefs : List Ref, gotGraphData : GotGraphData, graphDataIfGraphIsOn : Maybe GraphData }


type alias GraphData =
    { graphData : GotGraphData
    , graphModel : GraphModel
    , veryFirstMomentOfGraphHasPassed : Bool
    , contentToColorize : Maybe ContentID

    -- When graph animation starts, it is buggy somehow: Nodes are not shown in the center of the box, instead, they are shown at the top left of the box at the "very first moment" of initialization. So, we are setting "veryFirstMomentOfGraphHasPassed" as True just after the very first Tick msg of the graph, and we don't show the graph until that value becomes True
    }


type alias Ref =
    { text : String, id : String }


type alias GotGraphData =
    { titlesToShow : List String
    , contentIds : List Int
    , connections : List RefConnection
    }


type alias RefConnection =
    { a : Int, b : Int }


type alias ContentID =
    Int


type alias ContentDate =
    Date
