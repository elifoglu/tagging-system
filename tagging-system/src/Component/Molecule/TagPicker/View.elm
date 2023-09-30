module TagPicker.View exposing (viewTagPickerDiv)

import App.Model exposing (TagModuleVisibility(..), TagOption, TagPickerModuleModel)
import App.Msg exposing (WorkingOnWhichModule, Msg(..), TagInputType(..), TagPickerInputType(..))
import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (class, placeholder, selected, style, type_, value)
import Html.Events exposing (onClick, onInput)


getTagOptionsToShow : TagPickerModuleModel -> List TagOption
getTagOptionsToShow model =
    if model.input == "?" then
        --this branch is just for me to see all existing tags by entering "?" as search input
        model.allAvailableTagOptions
            |> List.filter (removeFilteredThingFirst model.tagIdToFilterOut)
            |> List.filter (\a -> not (List.member a model.selectedTagOptions))

    else
        model.allAvailableTagOptions
            |> List.filter (removeFilteredThingFirst model.tagIdToFilterOut)
            |> List.filter (\a -> String.contains model.input a.tagName)
            |> List.filter (\a -> not (List.member a model.selectedTagOptions))


removeFilteredThingFirst : Maybe String -> TagOption -> Bool
removeFilteredThingFirst tagIdToFilterOut tagOption =
    case tagIdToFilterOut of
        Just tagId ->
            tagOption.tagId /= tagId

        Nothing ->
            True


viewTagPickerDiv : TagPickerModuleModel -> WorkingOnWhichModule -> Html Msg
viewTagPickerDiv tagPickerModel workingOnWhichModule =
    div [] <|
        [ viewInput "text" "search tags..." tagPickerModel.input (tagCreateOrUpdateInputMessage workingOnWhichModule SearchInput)
        , viewSelecteds tagPickerModel (tagCreateOrUpdateInputMessage workingOnWhichModule OptionRemoved)
        , viewSelectInput tagPickerModel (tagCreateOrUpdateInputMessage workingOnWhichModule OptionClicked)
        ]


tagCreateOrUpdateInputMessage : WorkingOnWhichModule -> (something -> TagPickerInputType) -> something -> Msg
tagCreateOrUpdateInputMessage workingOnWhichModule a b =
    TagPickerModuleInputChanged workingOnWhichModule (a b)


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput toMsg, style "width" "100px" ] []


viewSelecteds : TagPickerModuleModel -> (TagOption -> msg) -> Html msg
viewSelecteds model toMsg =
    if List.isEmpty model.selectedTagOptions then
        text ""

    else
        div []
            (model.selectedTagOptions
                |> List.map (selectedTagOptionDiv toMsg)
            )


selectedTagOptionDiv : (TagOption -> msg) -> TagOption -> Html msg
selectedTagOptionDiv toMsg tagOption =
    div [ class "dropdown-content1", onClick (toMsg tagOption) ]
        [ div [ class "selectedTagOptionWithX" ]
            [ span [ class "selectedTagOption" ]
                [ text tagOption.tagName ]
            , span [ class "hide" ]
                [ text "X" ]
            ]
        ]


viewSelectInput : TagPickerModuleModel -> (TagOption -> msg) -> Html msg
viewSelectInput model toMsg =
    if String.length model.input < 1 then
        text ""

    else if List.isEmpty (getTagOptionsToShow model) then
        text ""

    else
        div [ class "dropdown-content2" ]
            (getTagOptionsToShow model
                |> List.map (viewOption toMsg)
            )


viewOption : (TagOption -> msg) -> TagOption -> Html msg
viewOption toMsg tagOption =
    div [ class "tagOptionToSelect", onClick (toMsg tagOption) ]
        [ text tagOption.tagName
        ]
