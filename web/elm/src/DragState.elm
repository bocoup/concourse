module DragState exposing (..)

import DragList


type DragState a
    = NotDragging (List a)
    | Dragging (DragList.DragList a)


map : (DragList.DragList a -> DragState a) -> DragState a -> DragState a
map f dragState =
    case dragState of
        NotDragging xs ->
            NotDragging xs

        Dragging dragList ->
            f dragList
