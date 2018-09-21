module SummaryGroup exposing (..)

import Grouped
import Html exposing (Html)
import Html.Attributes exposing (class)
import SummaryPipeline


type alias SummaryGroup =
    Grouped.Grouped (List SummaryPipeline.SummaryPipeline)


view : SummaryGroup -> Html SummaryPipeline.Msg
view ({ group, teamName } as summaryGroup) =
    let
        teamPipelines =
            if List.isEmpty group then
                [ Grouped.pipelineNotSetView ]
            else
                List.map SummaryPipeline.view group

        header =
            Grouped.header summaryGroup
    in
        Html.div [ class "pipeline-wrapper" ] <|
            case teamPipelines of
                [] ->
                    [ header ]

                p :: ps ->
                    -- Wrap the team name and the first pipeline together so the team name is not the last element in a column
                    List.append [ Html.div [ class "dashboard-team-name-wrapper" ] [ header, p ] ] ps
