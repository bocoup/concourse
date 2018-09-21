module Dashboard.Pipeline
    exposing
        ( Msg(..)
        , PipelineWithJobs
        , pipelineNotSetView
        , pipelineStatus
        , pipelineStatusFromJobs
        , statusAgeText
        )

import Concourse
import Duration
import Date
import Html exposing (..)
import Html.Attributes exposing (..)
import List.Extra
import Maybe.Extra
import Time exposing (Time)


type alias PipelineWithJobs =
    { pipeline : Concourse.Pipeline
    , jobs : List Concourse.Job
    , resourceError : Bool
    }


type Msg
    = Tooltip String String
    | TooltipHd String String
    | TogglePipelinePaused Concourse.Pipeline


pipelineNotSetView : Html msg
pipelineNotSetView =
    Html.div [ class "pipeline-wrapper" ]
        [ Html.div
            [ class "dashboard-pipeline no-set"
            ]
            [ Html.div
                [ class "dashboard-pipeline-content" ]
                [ Html.div [ class "no-set-wrapper" ]
                    [ Html.text "no pipelines set" ]
                ]
            ]
        ]


type alias Event =
    { succeeded : Bool
    , time : Time
    }


transitionTime : PipelineWithJobs -> Maybe Time
transitionTime pipeline =
    let
        events =
            pipeline.jobs |> List.filterMap jobEvent |> List.sortBy .time
    in
        events
            |> List.Extra.dropWhile .succeeded
            |> List.head
            |> Maybe.map Just
            |> Maybe.withDefault (List.Extra.last events)
            |> Maybe.map .time


jobEvent : Concourse.Job -> Maybe Event
jobEvent job =
    Maybe.map
        (Event <| jobSucceeded job)
        (transitionStart job)


jobSucceeded : Concourse.Job -> Bool
jobSucceeded =
    .finishedBuild
        >> Maybe.map (.status >> (==) Concourse.BuildStatusSucceeded)
        >> Maybe.withDefault False


transitionStart : Concourse.Job -> Maybe Time
transitionStart =
    .transitionBuild
        >> Maybe.map (.duration >> .startedAt)
        >> Maybe.Extra.join
        >> Maybe.map Date.toTime


sinceTransitionText : PipelineWithJobs -> Time -> String
sinceTransitionText pipeline now =
    Maybe.map (flip Duration.between now) (transitionTime pipeline)
        |> Maybe.map Duration.format
        |> Maybe.withDefault ""


statusAgeText : PipelineWithJobs -> Time -> String
statusAgeText pipeline =
    case pipelineStatus pipeline of
        Concourse.PipelineStatusPaused ->
            always "paused"

        Concourse.PipelineStatusPending ->
            always "pending"

        Concourse.PipelineStatusRunning ->
            always "running"

        _ ->
            sinceTransitionText pipeline


pipelineStatus : PipelineWithJobs -> Concourse.PipelineStatus
pipelineStatus { pipeline, jobs } =
    if pipeline.paused then
        Concourse.PipelineStatusPaused
    else
        pipelineStatusFromJobs jobs True


pipelineStatusFromJobs : List Concourse.Job -> Bool -> Concourse.PipelineStatus
pipelineStatusFromJobs jobs includeNextBuilds =
    let
        statuses =
            jobStatuses jobs
    in
        if containsStatus Concourse.BuildStatusPending statuses then
            Concourse.PipelineStatusPending
        else if includeNextBuilds && List.any (\job -> job.nextBuild /= Nothing) jobs then
            Concourse.PipelineStatusRunning
        else if containsStatus Concourse.BuildStatusFailed statuses then
            Concourse.PipelineStatusFailed
        else if containsStatus Concourse.BuildStatusErrored statuses then
            Concourse.PipelineStatusErrored
        else if containsStatus Concourse.BuildStatusAborted statuses then
            Concourse.PipelineStatusAborted
        else if containsStatus Concourse.BuildStatusSucceeded statuses then
            Concourse.PipelineStatusSucceeded
        else
            Concourse.PipelineStatusPending


jobStatuses : List Concourse.Job -> List (Maybe Concourse.BuildStatus)
jobStatuses jobs =
    List.concatMap
        (\job ->
            [ Maybe.map .status job.finishedBuild
            , Maybe.map .status job.nextBuild
            ]
        )
        jobs


containsStatus : Concourse.BuildStatus -> List (Maybe Concourse.BuildStatus) -> Bool
containsStatus =
    List.member << Just
