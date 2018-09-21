module DashboardBody exposing (..)

import DragState
import Dashboard.Pipeline as Pipeline
import Dashboard.Group.Tag as Tag
import SummaryGroup
import Grouped


type DashboardBody
    = WithTags (List (Tagged PreviewGroup.PreviewGroup))
    | WithTagsHd (List (Tagged SummaryGroup.SummaryGroup))
    | WithoutTags (List PreviewGroup.PreviewGroup)
    | WithoutTagsHd (List SummaryGroup.SummaryGroup)


type alias Tagged a =
    { item : a
    , tag : Tag.Tag
    }
