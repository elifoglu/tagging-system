module TagPicker.View exposing (viewTagPickerDiv)

import App.Model exposing (TagModuleVisibility(..), TagOption, TagPickerModuleModel)
import App.Msg exposing (KeyDownPlace(..), KeyDownType, Msg(..), TagInputType(..), TagPickerInputType(..), WorkingOnWhichModule)
import Component.KeydownHandler exposing (onKeyDown)
import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (class, placeholder, selected, style, type_, value)
import Html.Events exposing (onClick, onFocus, onInput)
import TypedSvg.Events exposing (onFocusOut)


getTagOptionsToShow : TagPickerModuleModel -> List TagOption
getTagOptionsToShow model =
    if model.showTagOptionList == False then []
    else
        model.allAvailableTagOptions
            |> List.filter (removeFilteredThingFirst model.tagIdToFilterOut)
            |> List.filter (\a -> if model.input == "" then True else String.contains model.input a.tagName)
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
        [ viewInput "text" "search tags..." tagPickerModel.input (TagPickerModuleInputChanged workingOnWhichModule ToggleSelectionList) (tagCreateOrUpdateInputMessage workingOnWhichModule SearchInput) (KeyDown (TagPickerModuleInput workingOnWhichModule))
        , viewSelecteds tagPickerModel (tagCreateOrUpdateInputMessage workingOnWhichModule OptionRemoved)
        , viewSelectInput tagPickerModel (tagCreateOrUpdateInputMessage workingOnWhichModule OptionClicked)
        ]


tagCreateOrUpdateInputMessage : WorkingOnWhichModule -> (something -> TagPickerInputType) -> something -> Msg
tagCreateOrUpdateInputMessage workingOnWhichModule a b =
    TagPickerModuleInputChanged workingOnWhichModule (a b)


viewInput : String -> String -> String -> msg -> (String -> msg) -> (KeyDownType -> msg) -> Html msg
viewInput t p v focusMsg inputMsg keydownMsg =
    input [ type_ t, placeholder p, value v, selected True, onInput inputMsg, onClick focusMsg, onKeyDown keydownMsg,  style "width" "100px" ] []


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
    if List.isEmpty (getTagOptionsToShow model) then
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
