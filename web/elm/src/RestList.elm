module RestList exposing (..)

import ListHelpers exposing (..)


type alias RestList a =
    { before : List a
    , after : List a
    }


restLists : List a -> List (RestList a)
restLists xs =
    List.map2 RestList (prefixes xs) (suffixes xs)


toList : RestList a -> List a
toList restList =
    restList.before ++ restList.after
