module BioGroup.Util exposing (setActiveness, changeDisplayInfoValueIfUrlMatchesAndGroupIsActive, gotBioGroupToBioGroup)

import BioGroup.Model exposing (BioGroup)
import DataResponse exposing (BioGroupUrl, GotBioGroup, GotContent, GotContentDate, GotTag)


gotBioGroupToBioGroup : GotBioGroup -> BioGroup
gotBioGroupToBioGroup got =
    BioGroup got.url
        got.title
        got.displayIndex
        (gotBioGroupInfoToBioGroupInfo got.info)
        got.bioGroupId
        got.bioItemOrder
        False
        True


gotBioGroupInfoToBioGroupInfo : Maybe String -> Maybe String
gotBioGroupInfoToBioGroupInfo gotBioGroupInfo =
    case gotBioGroupInfo of
        Just "null" ->
            Nothing

        Just info ->
            Just (String.replace "*pipe*" "|" info)

        Nothing ->
            Nothing


setActiveness : BioGroupUrl -> BioGroup -> BioGroup
setActiveness url bioGroup =
    if bioGroup.url == url then
        { bioGroup | isActive = True }

    else
        { bioGroup | isActive = False}



changeDisplayInfoValueIfUrlMatchesAndGroupIsActive : String -> BioGroup -> BioGroup
changeDisplayInfoValueIfUrlMatchesAndGroupIsActive url bioGroup =
    if bioGroup.url == url && bioGroup.isActive then
        { bioGroup | displayInfo = not bioGroup.displayInfo }

    else
        bioGroup
