module ZipList exposing (..)

import ListHelpers exposing (..)
import RestList


type alias ZipList a =
    { item : a
    , rest : RestList.RestList a
    }


zipLists : List a -> List (ZipList a)
zipLists xs =
    List.map2 RestList.RestList (prefixes xs) (suffixes xs |> List.drop 1)
        |> List.map2 ZipList xs


toList : ZipList a -> List a
toList { item, rest } =
    rest.before ++ [ item ] ++ rest.after
