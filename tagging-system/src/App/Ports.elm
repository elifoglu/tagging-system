port module App.Ports exposing (consoleLog, sendTitle, title)

import App.Model exposing (Initializable(..), MaySendRequest(..), Model, Page(..), UpdateContentModuleModel(..))


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
                    title (initialized.tag.name ++ " - tagging system")


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

        NotFoundPage ->
            title "oops - tagging system"

        MaintenancePage ->
            title "bakım çalışması - tagging system"


port consoleLog : String -> Cmd msg
