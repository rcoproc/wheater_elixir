
defmodule App.SimpleWeather do
  @moduledoc """
    Get The cities Weather with Task async/wait
  """

  @doc """
  Get Temp Weather in default cities:

  ["Campo Grande", "Cuiabá", "Sao Paulo", "Belo Horizonte", "Salvador"]

  ## Example:
  
     iex-> App.SimpleWeather.start
  """
  def start() do 
    ["Campo Grande", "Cuiabá", "Sao Paulo", "Belo Horizonte", "Salvador"]
    |> parallel_cities
  end

  @doc """
  Get Temp Weather in List of Cities.

  ## Example:
  
     iex-> App.SimpleWeather.start(["Belem"])
      
  """
  def start(cities), do: parallel_cities(cities) 

  defp parallel_cities(cities) do
    cities
    |> Enum.map(&create_task/1)
    |> Enum.map(&Task.await/1)
  end

  defp create_task(city) do
   Task.async(fn -> temperature_of(city) end)
  end

  defp temperature_of(location) do
    result = get_endpoint(location) |> HTTPoison.get |> parser_response
    case result do
      {:ok, temp} ->
        "#{location}: #{temp} °C"
      :error ->
        "#{location} not found"
    end
  end

  defp get_endpoint(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{get_appid()}"
  end

  defp get_appid() do
    "bc0864ef50f0056c78dc59a5532d58e1"
  end

  defp parser_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
  end

  defp parser_response(_), do: :error

  defp compute_temperature(json) do
    try do
      temp = json["main"]["temp"] |> kelvin_to_celsius
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp kelvin_to_celsius(kelvin) do
    (kelvin - 273.15) |> Float.round(1)
  end

end
