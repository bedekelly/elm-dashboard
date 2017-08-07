module Main exposing (..)

import Html exposing (Html, blockquote, div, em, h1, h2, tbody, td, text, th, thead, tr, h3)
import Html.Attributes exposing (href, rel, style, id, class)
import Http
import Json.Decode exposing (at, field, int, list, map2, string)
import Plot exposing (BarGroup, Bars, defaultBarsPlotCustomizations, group, groups, histogram, normalAxis, viewBars, viewBarsCustom)


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


view : Model -> Html msg
view model =
    div [ id "page" ]
        [ styles
        , heading
        , description
        , contentView model
        ]


contentView : Model -> Html msg
contentView model =
    let
        contents =
            case model.categories of
                [] ->
                    [ h3 [] [ text "Loading..." ] ]

                data ->
                    [ barchart data, table data ]
    in
        div [ id "contents " ] contents


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
    h1 [] [ headingText ]


description : Html msg
description =
    blockquote [] [ em [] [ descriptionText ] ]


barchart : Categories -> Html msg
barchart allData =
    let
        data =
            List.take 5 allData
    in
        viewBarsCustom customizations bars data


table : Categories -> Html msg
table data =
    list2Table data


stylesheet : String -> Html msg
stylesheet name =
    Html.node "link"
        [ rel "stylesheet"
        , href ("static/css/" ++ name ++ ".css")
        ]
        []


styles : Html msg
styles =
    div [] (List.map stylesheet [ "style" ])


bars : Bars Categories msg
bars =
    groups
        (List.map
            (\category ->
                group category.name
                    [ (toFloat (abs category.amount)) / 100
                    ]
            )
        )


customizations : Plot.PlotCustomizations msg
customizations =
    let
        cs =
            defaultBarsPlotCustomizations
    in
        { cs | width = 900 }


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
        , td []
            [ -amount
                |> (\amount -> amount // 100)
                |> toString
                |> (\amount -> "£ " ++ amount)
                |> text
            ]
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
            "https://fux7yt6bl8.execute-api.eu-west-2.amazonaws.com/"
                ++ "prod/category"

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
