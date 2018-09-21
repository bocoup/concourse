module DragItem exposing (..)

import DragState
import DragZone
import DropZone
import List.Extra


type DragItem a
    = DragZone (DragZone.DragZoneState a)
    | DropZone (DropZone.DropZoneState a)


items : DragState.DragState a -> List (DragItem a)
items dragState =
    case dragState of
        DragState.NotDragging items ->
            List.Extra.interweave
                (List.repeat (List.length items + 1) (DropZone DropZone.Disabled))
                (DragZone.draggables items |> List.map DragZone)

        DragState.Dragging dragList ->
            List.Extra.interweave
                (dragList |> DropZone.dropZones |> List.map DropZone)
                (dragList |> DragZone.nonDraggables |> List.map DragZone)
