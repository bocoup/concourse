module Draggable exposing (..)

import DragDrop
import ZipList


type DragItem a
    = DragItem a
    | DropItem (DropZone a)


type DropZone a
    = On
    | Off (DragDrop.DragAction a)


type Msg a
    = StartDragging (ZipList.ZipList a)
    | Drag (DragDrop.DragAction a)
    | Drop


update : Msg a -> DragDrop.DragState a -> DragDrop.DragState a
update msg dragState =
    case msg of
        StartDragging zipList ->
            case dragState of
                DragDrop.NotDragging _ ->
                    DragDrop.Dragging (DragDrop.startDrag zipList)

                DragDrop.Dragging dragList ->
                    DragDrop.Dragging dragList

        Drag action ->
            dragState |> DragDrop.map action

        Drop ->
            case dragState of
                DragDrop.NotDragging xs ->
                    DragDrop.NotDragging xs

                DragDrop.Dragging dragList ->
                    DragDrop.NotDragging (DragDrop.drop dragList)


dragView : DragDrop.DragState a -> List (DragItem a)
dragView dragState =
    case dragState of
        DragDrop.NotDragging items ->
            (items |> List.concatMap (\a -> [ DropItem (Off (DragDrop.dragBefore a)), DragItem a ]))
                ++ [ DropItem (Off DragDrop.dragToEnd) ]

        DragDrop.Dragging { before, after } ->
            (before |> List.concatMap (\a -> [ DropItem (Off (DragDrop.dragBefore a)), DragItem a ]))
                ++ [ DropItem On ]
                ++ (after |> List.concatMap (\a -> [ DropItem (Off (DragDrop.dragBefore a)), DragItem a ]) |> List.drop 1)
                ++ [ DropItem (Off DragDrop.dragToEnd) ]
