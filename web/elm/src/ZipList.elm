module ZipList exposing (..)

import List.Extra


type alias ZipList a =
    { before : List a
    , current : a
    , after : List a
    }


prefixes : List a -> List (List a)
prefixes =
    List.reverse >> suffixes >> List.map List.reverse >> List.reverse


suffixes : List a -> List (List a)
suffixes =
    List.Extra.scanr (::) []


uncurry3 : (a -> b -> c -> d) -> ( a, b, c ) -> d
uncurry3 f ( x, y, z ) =
    f x y z


zipLists : List a -> List (ZipList a)
zipLists xs =
    List.Extra.zip3 (prefixes xs) xs (suffixes xs |> List.drop 1)
        |> List.map (uncurry3 ZipList)
