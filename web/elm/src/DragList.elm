module DragList exposing (..)

import RestList
import ZipList


type alias DragList a =
    { initial : RestList.RestList a
    , current : RestList.RestList a
    , dragging : a
    }


dragStart : ZipList.ZipList a -> DragList a
dragStart zipList =
    { initial = zipList.rest
    , current = zipList.rest
    , dragging = zipList.item
    }


dragTo : RestList.RestList a -> DragList a -> DragList a
dragTo restList dragList =
    { dragList | current = restList }


dragOff : DragList a -> DragList a
dragOff dragList =
    { dragList | current = dragList.initial }


drop : DragList a -> List a
drop dragList =
    ZipList.ZipList dragList.dragging dragList.current
        |> ZipList.toList


toList : DragList a -> List a
toList =
    .initial >> RestList.toList
