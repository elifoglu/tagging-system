module TagPicker.View exposing (TagOption, TagPickerModuleModel, viewTagPickerDiv)

import App.Msg exposing (Msg(..), TagInputType(..), TagPickerInputType(..))
import Html exposing (Html, br, div, input, option, select, text)
import Html.Attributes exposing (placeholder, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)


type alias TagOption =
    { tagId : String
    , tagName : String
    }


type alias TagPickerModuleModel =
    { input : String
    , allAvailableTagOptions : List TagOption
    , selectedTagOptions : List TagOption
    }


getTagOptionsToShow : TagPickerModuleModel -> List TagOption
getTagOptionsToShow model =
    model.allAvailableTagOptions
        |> List.filter (\a -> String.contains model.input a.tagName)
        |> List.filter (\a -> not (List.member a model.selectedTagOptions))


viewTagPickerDiv : TagPickerModuleModel -> Html Msg
viewTagPickerDiv tagPickerModel =
    div [] <|
        List.intersperse (br [] [])
            [ viewInput "text" "search tags..." tagPickerModel.input TagPickerModuleSearchInputChanged
            , viewSelectInput tagPickerModel TagPickerModuleOptionClicked
            ]

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


viewSelectInput : TagPickerModuleModel -> (String -> msg) -> Html msg
viewSelectInput model toMsg =
    if String.length model.input < 2 then
        text ""

    else
        select [ value model.input ]
            (getTagOptionsToShow model
                |> List.map (viewOption model.input toMsg)
            )



viewOption : String -> (String -> msg) -> TagOption -> Html msg
viewOption searchText toMsg tagOption =
    option
        [ value tagOption.tagName
        , onClick (toMsg tagOption.tagId)
        , selected
            (if searchText == tagOption.tagName then
                True

             else
                False
            )
        ]
        [ text tagOption.tagName ]



--(createTagInputMessage Input)
