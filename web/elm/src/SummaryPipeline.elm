module SummaryPipeline exposing (..)

import Concourse.PipelineStatus
import Dashboard.Pipeline as Pipeline
import Html
import Html.Attributes exposing (attribute, class, classList, href)
import Html.Events exposing (onMouseEnter)
import Routes


type SummaryPipeline
    = SummaryPipeline Pipeline.PipelineWithJobs


type Msg
    = Tooltip String String


view : SummaryPipeline -> Html.Html Msg
view (SummaryPipeline { pipeline, jobs, resourceError }) =
    Html.div
        [ classList
            [ ( "dashboard-pipeline", True )
            , ( "dashboard-paused", pipeline.paused )
            , ( "dashboard-running", List.any (\job -> job.nextBuild /= Nothing) jobs )
            , ( "dashboard-status-" ++ Concourse.PipelineStatus.show (Pipeline.pipelineStatusFromJobs jobs False), not pipeline.paused )
            ]
        , attribute "data-pipeline-name" pipeline.name
        , attribute "data-team-name" pipeline.teamName
        ]
        [ Html.div [ class "dashboard-pipeline-banner" ] []
        , Html.div
            [ class "dashboard-pipeline-content"
            , onMouseEnter <| Tooltip pipeline.name pipeline.teamName
            ]
            [ Html.a [ href <| Routes.pipelineRoute pipeline ]
                [ Html.div
                    [ class "dashboardhd-pipeline-name"
                    , attribute "data-team-name" pipeline.teamName
                    ]
                    [ Html.text pipeline.name ]
                ]
            ]
        , Html.div [ classList [ ( "dashboard-resource-error", resourceError ) ] ] []
        ]
