module Main exposing (..)

import Html exposing (Html, div, h1, h2, tbody, td, text, th, thead, tr, blockquote, em)
import Html.Attributes exposing (style)
import Http
import Json.Decode exposing (at, field, int, list, map2, string)
import Plot
    exposing
        ( BarGroup
        , Bars
        , group
        , groups
        , histogram
        , normalAxis
        , viewBarsCustom
        , viewBars
        )


-- Models and Messages


type alias Model =
    { categories : Categories
    }


type alias Category =
    { name : String
    , amount : Int
    }


type alias Categories =
    List Category


type Msg
    = DataLoaded (Result Http.Error Categories)



-- Main Program


main : Program Never Model Msg
main =
    Html.program
        { init = ( Model [], loadData )
        , update = update
        , subscriptions = \m -> Sub.none
        , view = view
        }



-- View


headingStyle : List ( String, String )
headingStyle =
    [ ( "margin-left", "25px" ) ]


tableStyle : List ( String, String )
tableStyle =
    [ ( "display", "inline-block" ), ( "margin-left", "20px" ), ( "margin-top", "10px" ) ]


headingText : Html msg
headingText =
    text "Total Spending by Category"


descriptionText : Html msg
descriptionText =
    text """
Fetching JSON data from an external API, formatting it
into a table and displaying it as a bar-chart using the
Elm-Plot library.
  """


heading : Html msg
heading =
    h1 [ style headingStyle ] [ headingText ]


description : Html msg
description =
    blockquote [] [ em [] [ descriptionText ] ]


barchart : Categories -> Html msg
barchart data =
    div [] [ viewBarsCustom customizations bars data ]


table : Categories -> Html msg
table data =
    div [ style tableStyle ] [ list2Table data ]


view : Model -> Html msg
view model =
    case model.categories of
        [] ->
            h2 [] [ text "Loading..." ]

        data ->
            div [] [ heading, description, barchart data, table data ]


bars : Bars Categories msg
bars =
    groups
        (List.map
            (\category ->
                group category.name [ (toFloat (abs category.amount)) / 100 ]
            )
        )


customizations : Plot.PlotCustomizations msg
customizations =
    let
        cs =
            Plot.defaultBarsPlotCustomizations
    in
        { cs | width = 2000, margin = { top = 0, right = 40, bottom = 40, left = 50 } }


list2Table : Categories -> Html msg
list2Table categories =
    Html.table []
        [ thead []
            [ tr []
                [ th [] [ text "Category" ]
                , th [] [ text "Amount" ]
                ]
            ]
        , tbody []
            (List.map
                categoryRow
                categories
            )
        ]


categoryRow : Category -> Html msg
categoryRow { name, amount } =
    tr []
        [ td [] [ text name ]
        , td [] [ text <| (\x -> "£ " ++ x) <| toString <| (\x -> (x // 100)) <| -amount ]
        ]



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataLoaded (Ok cats) ->
            ( Model cats, Cmd.none )

        DataLoaded (Err _) ->
            ( model, Cmd.none )


loadData : Cmd Msg
loadData =
    let
        url =
            "https://fux7yt6bl8.execute-api.eu-west-2.amazonaws.com/prod/category"

        request =
            Http.get url decodeData
    in
        Http.send DataLoaded request


decodeData : Json.Decode.Decoder (List Category)
decodeData =
    field "categories"
        ((list
            (map2
                Category
                (field "name" string)
                (field "amount" int)
            )
         )
        )
