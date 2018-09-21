module DragZone exposing (..)

import DragList
import ZipList


type DragZoneState a
    = Draggable (ZipList.ZipList a)
    | NonDraggable a


draggables : List a -> List (DragZoneState a)
draggables =
    ZipList.zipLists >> List.map Draggable


nonDraggables : DragList.DragList a -> List (DragZoneState a)
nonDraggables =
    DragList.toList >> ZipList.zipLists >> List.map (.item >> NonDraggable)
