module Grouped exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (class, classList)


type alias Grouped a =
    { group : a
    , teamName : String
    }


header : Grouped a -> Html msg
header group =
    Html.div [ class "dashboard-team-name" ] [ Html.text group.teamName ]


pipelineNotSetView : Html msg
pipelineNotSetView =
    Html.div
        [ class "dashboard-pipeline" ]
        [ Html.div
            [ classList
                [ ( "dashboard-pipeline-content", True )
                , ( "no-set", True )
                ]
            ]
            [ Html.a [] [ Html.text "no pipelines set" ]
            ]
        ]
