port module App.Ports exposing (consoleLog, sendTitle, title, storeTagTextViewType)

import App.Model exposing (Initializable(..), Model, Page(..))


port title : String -> Cmd a


sendTitle : Model -> Cmd msg
sendTitle model =
    case model.activePage of
        TagPage status ->
            case status of
                NonInitialized _ ->
                    Cmd.none

                Initialized initialized ->
                    title (initialized.tag.name ++ " - tagging system")

        ContentSearchPage _ _ _ ->
            title "search - tagging system"

        NotFoundPage ->
            title "oops - tagging system"


port storeTagTextViewType : String -> Cmd msg

port consoleLog : String -> Cmd msg
