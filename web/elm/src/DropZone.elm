module DropZone exposing (..)

import DragEvent
import DragList
import List.Extra
import RestList
import Html exposing (Html)
import Html.Attributes exposing (classList)
import Html.Events exposing (on)
import Json.Decode


type DropZoneState a
    = On
    | Off { dragEnter : RestList.RestList a }
    | Disabled


off : RestList.RestList a -> DropZoneState a
off restList =
    Off { dragEnter = restList }


dragEnter : DropZoneState a -> Maybe (RestList.RestList a)
dragEnter item =
    case item of
        Off { dragEnter } ->
            Just dragEnter

        _ ->
            Nothing


dropZones : DragList.DragList a -> List (DropZoneState a)
dropZones dragList =
    dragList.initial
        |> RestList.toList
        |> RestList.restLists
        |> List.map off
        |> List.Extra.replaceIf (dragEnter >> (==) (Just dragList.current)) On


view : DropZoneState a -> Html (DragEvent.Msg a)
view dropZoneState =
    case dropZoneState of
        On ->
            Html.div
                [ classList
                    [ ( "drop-area", True )
                    , ( "active", False )
                    , ( "over", True )
                    , ( "animation", True )
                    ]
                , on "dragleave" (Json.Decode.succeed DragEvent.DragLeave)
                ]
                [ Html.text "" ]

        Off { dragEnter } ->
            Html.div
                [ classList
                    [ ( "drop-area", True )
                    , ( "active", True )
                    , ( "over", False )
                    , ( "animation", False )
                    ]
                , on "dragenter" (Json.Decode.succeed (DragEvent.DragEnter dragEnter))
                ]
                [ Html.text "" ]

        Disabled ->
            Html.div
                [ classList
                    [ ( "drop-area", True )
                    , ( "active", False )
                    , ( "over", False )
                    , ( "animation", False )
                    ]
                ]
                [ Html.text "" ]
