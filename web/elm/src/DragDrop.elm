module DragDrop exposing (..)

import List.Extra
import ZipList


type alias DragAction a =
    DragList a -> DragList a


type DragState a
    = NotDragging (List a)
    | Dragging (DragList a)


map : DragAction a -> DragState a -> DragState a
map f dragState =
    case dragState of
        NotDragging xs ->
            NotDragging xs

        Dragging dragList ->
            Dragging (f dragList)


type alias DragList a =
    { initialState : ZipList.ZipList a
    , before : List a
    , dragging : a
    , after : List a
    }


startDrag : ZipList.ZipList a -> DragList a
startDrag ({ before, current, after } as initialState) =
    { initialState = initialState
    , before = before
    , dragging = current
    , after = after
    }


dragBefore : a -> DragList a -> DragList a
dragBefore a dragList =
    case ( List.Extra.splitWhen ((==) a) dragList.before, List.Extra.splitWhen ((==) a) dragList.after ) of
        ( Just ( bef, aft ), Nothing ) ->
            { initialState = dragList.initialState
            , before = bef
            , dragging = dragList.dragging
            , after = aft ++ dragList.after
            }

        ( Nothing, Just ( bef, aft ) ) ->
            { initialState = dragList.initialState
            , before = dragList.before ++ bef
            , dragging = dragList.dragging
            , after = aft
            }

        _ ->
            dragOff dragList


dragToEnd : DragList a -> DragList a
dragToEnd dragList =
    { initialState = dragList.initialState
    , before = dragList.before ++ dragList.after
    , dragging = dragList.dragging
    , after = []
    }


dragOff : DragList a -> DragList a
dragOff dragList =
    startDrag dragList.initialState


drop : DragList a -> List a
drop { before, dragging, after } =
    before ++ [ dragging ] ++ after
