module App.GraphModel exposing (..)

import Force
import Graph exposing (Graph, NodeId)


type alias GraphModel =
    { drag : Maybe Drag
    , graph : Graph Entity ()
    , simulation : Force.State NodeId
    , currentlyDraggedNodeId : Maybe Int
    }


type alias Entity =
    Force.Entity NodeId { value : String }


type alias Drag =
    { start : ( Float, Float )
    , current : ( Float, Float )
    , index : NodeId
    }
