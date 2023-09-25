port module App.Ports exposing (consoleLog, openNewTab, sendTitle, title)

import App.Model exposing (Initializable(..), MaySendRequest(..), Model, Page(..), UpdateContentPageModel(..))


port title : String -> Cmd a


sendTitle : Model -> Cmd msg
sendTitle model =
    case model.activePage of
        ContentPage status ->
            case status of
                NonInitialized _ ->
                    Cmd.none

                Initialized content ->
                    case content.title of
                        Just t ->
                            title (t ++ " - tagging system")

                        Nothing ->
                            title (String.fromInt content.contentId ++ " - tagging system")

        TagPage status ->
            case status of
                NonInitialized _ ->
                    Cmd.none

                Initialized initialized ->
                    if initialized.pagination.currentPage == 1 then
                        title (initialized.tag.name ++ " - tagging system")

                    else
                        title (initialized.tag.name ++ " " ++ " (" ++ String.fromInt initialized.pagination.currentPage ++ ") - tagging system")

        CreateContentPage _ ->
            title "create new content - tagging system"

        UpdateContentPage status ->
            case status of
                NotInitializedYet _ ->
                    title <| "update content - tagging system"

                GotContentToUpdate updateContentPageData ->
                    if String.isEmpty updateContentPageData.title then
                        title <| "update content - " ++ String.fromInt updateContentPageData.contentId ++ " - tagging system"

                    else
                        title <| "update content - " ++ updateContentPageData.title ++ " - tagging system"

                UpdateRequestIsSent _ ->
                    Cmd.none

        CreateTagPage _ ->
            title "create new tag - tagging system"

        UpdateTagPage status ->
            case status of
                NoRequestSentYet ( _, tagId ) ->
                    title <| "update tag - " ++ tagId ++ " - tagging system"

                _ ->
                    Cmd.none

        ContentSearchPage _ _ ->
            title "içerik ara - tagging system"

        GraphPage _ ->
            title "graf - tagging system"

        NotFoundPage ->
            title "oops - tagging system"

        MaintenancePage ->
            title "bakım çalışması - tagging system"


port consoleLog : String -> Cmd msg


port openNewTab : String -> Cmd msg
