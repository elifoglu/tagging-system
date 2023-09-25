module BioItem.Util exposing (getBioItemById, gotBioItemToBioItem, separatorBioItem)

import BioItem.Model exposing (BioItem)
import DataResponse exposing (BioItemID, GotBioGroup, GotBioItem, GotContent, GotContentDate, GotTag)


gotBioItemToBioItem : GotBioItem -> BioItem
gotBioItemToBioItem got =
    BioItem got.bioItemID got.name got.groups got.groupNames got.colorHex (gotBioItemInfoToBioItemInfo got.info)


gotBioItemInfoToBioItemInfo : Maybe String -> Maybe String
gotBioItemInfoToBioItemInfo gotBioItemInfo =
    case gotBioItemInfo of
        Just "null" ->
            Nothing

        Just info ->
            Just (String.replace "*pipe*" "|" info)

        Nothing ->
            Nothing


getBioItemById : List BioItem -> BioItemID -> BioItem
getBioItemById bioItems bioItemID =
    bioItems
        |> List.filter (\bioItem -> bioItem.bioItemID == bioItemID)
        |> List.head
        |> Maybe.withDefault separatorBioItem


separatorBioItem : BioItem --if there is an invalid bioItemId in the bioItems of a bioGroup, it is on purpose and used as a separator to create a meaningful separation for different kind of bioItem groups in the same bioGroup
separatorBioItem =
    BioItem 0 "" [] [] Nothing Nothing
