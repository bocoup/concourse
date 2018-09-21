module ListHelpers exposing (..)

import List.Extra


prefixes : List a -> List (List a)
prefixes =
    List.reverse >> suffixes >> List.map List.reverse >> List.reverse


suffixes : List a -> List (List a)
suffixes =
    List.Extra.scanr (::) []
