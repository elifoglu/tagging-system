module ForceDirectedGraphUtil exposing (maybeGetAt, updateGraph)

import App.GraphModel exposing (GraphModel)
import App.Model exposing (Entity, Model)
import App.Msg exposing (Msg(..))
import Force exposing (State)
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import List.Extra exposing (getAt)


updateGraph : Msg -> GraphModel -> GraphModel
updateGraph msg ({ drag, graph, simulation, currentlyDraggedNodeId } as model) =
    case msg of
        Tick t ->
            let
                ( newState, list ) =
                    Force.tick simulation <| List.map .label <| Graph.nodes graph
            in
            case drag of
                Nothing ->
                    GraphModel drag (updateGraphWithList graph list) newState currentlyDraggedNodeId

                Just { current, index } ->
                    GraphModel drag
                        (Graph.update index
                            (Maybe.map (updateNode current))
                            (updateGraphWithList graph list)
                        )
                        newState
                        currentlyDraggedNodeId

        DragStart index xy ->
            GraphModel (Just (App.Model.Drag xy xy index)) graph simulation (Just index)

        DragAt xy ->
            case drag of
                Just { start, index } ->
                    GraphModel (Just (App.Model.Drag start xy index))
                        (Graph.update index (Maybe.map (updateNode xy)) graph)
                        (Force.reheat simulation)
                        currentlyDraggedNodeId

                Nothing ->
                    GraphModel Nothing graph simulation currentlyDraggedNodeId

        DragEnd xy ->
            case drag of
                Just { start, index } ->
                    GraphModel Nothing
                        (Graph.update index (Maybe.map (updateNode xy)) graph)
                        simulation
                        Nothing

                Nothing ->
                    GraphModel Nothing graph simulation Nothing

        _ ->
            model


updateNode : ( Float, Float ) -> NodeContext Entity () -> NodeContext Entity ()
updateNode ( x, y ) nodeCtx =
    let
        nodeValue =
            nodeCtx.node.label
    in
    updateContextWithValue nodeCtx { nodeValue | x = x, y = y }


updateGraphWithList : Graph Entity () -> List Entity -> Graph Entity ()
updateGraphWithList =
    let
        graphUpdater value =
            Maybe.map (\ctx -> updateContextWithValue ctx value)
    in
    List.foldr (\node graph -> Graph.update node.id (graphUpdater node) graph)


updateContextWithValue : NodeContext Entity () -> Entity -> NodeContext Entity ()
updateContextWithValue nodeCtx value =
    let
        node =
            nodeCtx.node
    in
    { nodeCtx | node = { node | label = value } }


maybeGetAt : Maybe Int -> List Int -> Maybe Int
maybeGetAt maybeInt ints =
    case maybeInt of
        Just int ->
            getAt int ints

        Nothing ->
            Nothing
