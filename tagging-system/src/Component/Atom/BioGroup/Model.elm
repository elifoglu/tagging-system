module BioGroup.Model exposing (..)



type alias BioGroup =
    { url : String
    , title : String
    , displayIndex : Int
    , info : Maybe String
    , bioGroupId: Int
    , bioItemOrder : List Int
    , isActive : Bool
    , displayInfo : Bool
    }
