module PreviewGroup exposing (..)

import Concourse.PipelineStatus
import Dashboard.Pipeline as Pipeline
import DragEvent
import DragItem
import DragState
import DragZone
import DropZone
import Grouped
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, classList, draggable, id)
import Html.Events exposing (on)
import Json.Decode
import PreviewPipeline
import ZipList


type alias PreviewGroup =
    Grouped.Grouped (DragState.DragState PreviewPipeline.PreviewPipeline)


type Msg
    = DragMsg (DragEvent.Msg PreviewPipeline.PreviewPipeline)
    | PipelineMsg PreviewPipeline.Msg


view : PreviewGroup -> Html Msg
view ({ group, teamName } as grouped) =
    Html.div [ id teamName, class "dashboard-team-group", attribute "data-team-name" teamName ]
        [ Html.div [ class "pin-wrapper" ]
            [ Html.div [ class "dashboard-team-header" ] [ Grouped.header grouped ] ]
        , Html.div [ class "dashboard-team-pipelines" ]
            (group |> DragItem.items |> List.map viewDragItem)
        ]


viewDragItem : DragItem.DragItem PreviewPipeline.PreviewPipeline -> Html Msg
viewDragItem dragItem =
    case dragItem of
        DragItem.DragZone dragZoneState ->
            case dragZoneState of
                DragZone.Draggable ({ item, rest } as zipList) ->
                    case item of
                        PreviewPipeline.PreviewPipeline now pipeline ->
                            Html.div
                                (pipelineAttrs pipeline ++ draggableAttrs zipList)
                                [ Html.div [ class "dashboard-pipeline-banner" ] []
                                , Html.map PipelineMsg <| PreviewPipeline.view item
                                ]

                DragZone.NonDraggable ((PreviewPipeline.PreviewPipeline now pipeline) as item) ->
                    Html.div
                        (pipelineAttrs pipeline)
                        [ Html.div [ class "dashboard-pipeline-banner" ] []
                        , Html.map PipelineMsg <| PreviewPipeline.view item
                        ]

        DragItem.DropZone dropZoneState ->
            Html.map DragMsg <| DropZone.view dropZoneState


pipelineAttrs : Pipeline.PipelineWithJobs -> List (Html.Attribute msg)
pipelineAttrs pipeline =
    [ classList
        [ ( "dashboard-pipeline", True )
        , ( "dashboard-paused", pipeline.pipeline.paused )
        , ( "dashboard-running", not <| List.isEmpty <| List.filterMap .nextBuild pipeline.jobs )
        , ( "dashboard-status-" ++ Concourse.PipelineStatus.show (Pipeline.pipelineStatusFromJobs pipeline.jobs False), not pipeline.pipeline.paused )
        , ( "dragging", False )
        ]
    , attribute "data-pipeline-name" pipeline.pipeline.name
    ]


draggableAttrs : ZipList.ZipList PreviewPipeline.PreviewPipeline -> List (Html.Attribute Msg)
draggableAttrs zipList =
    [ attribute "ondragstart" "event.dataTransfer.setData('text/plain', '');"
    , draggable "true"
    , on "dragstart" (Json.Decode.succeed (DragMsg <| DragEvent.DragStart zipList))
    , on "dragend" (Json.Decode.succeed (DragMsg DragEvent.Drop))
    ]
