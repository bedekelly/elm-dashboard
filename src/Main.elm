module Main exposing (..)

import Html exposing (Html, div, h2, text, table, tr, th, td, thead, tbody)
import Http
import Json.Decode exposing (at, list, map2, field, string, int)


main : Program Never Model Msg
main =
    Html.program
        { init = ( Model [], loadData )
        , update = update
        , subscriptions = \m -> Sub.none
        , view = view
        }


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


view : Model -> Html msg
view model =
    case model.categories of
        [] ->
            h2 [] [ text "Loading..." ]

        cats ->
            list2Table cats


list2Table : Categories -> Html msg
list2Table categories =
    table []
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
        , td [] [ text <| toString amount ]
        ]


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
