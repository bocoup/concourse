module DragEvent exposing (..)

import DragList
import DragState
import RestList
import ZipList


type Msg a
    = DragStart (ZipList.ZipList a)
    | DragEnter (RestList.RestList a)
    | DragLeave
    | Drop


update : Msg a -> DragState.DragState a -> DragState.DragState a
update msg =
    case msg of
        DragStart zipList ->
            always (DragList.dragStart zipList |> DragState.Dragging)

        DragEnter restList ->
            DragState.map (DragList.dragTo restList >> DragState.Dragging)

        DragLeave ->
            DragState.map (DragList.dragOff >> DragState.Dragging)

        Drop ->
            DragState.map (DragList.drop >> DragState.NotDragging)
