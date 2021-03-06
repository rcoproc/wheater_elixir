defmodule App.Weather do

  @moduledoc """
    Get The cities Weather with Spawn Process / Send
  """

  @doc """
  Get Temp Weather in List of Cities.

  ## Example:

     iex-> App.Weather.start(["Belem", "Campo Grande", "Sao Paulo"])

  """
  def start(cities) do
    manager_pid = spawn(__MODULE__, :manager, [[], Enum.count(cities)])

    cities |> Enum.map(fn city ->
      pid = spawn(__MODULE__, :get_temperature, [])
      send pid, {manager_pid, city}
    end)
  end

  def temperature_of(location) do
    result = get_endpoint(location) |> HTTPoison.get |> parser_response
    case result do
      {:ok, temp} ->
        "#{location}: #{temp} °C"
      :error ->
        "#{location} not found"
    end
  end

  def get_temperature() do
    receive do
      {manager_pid, location} ->
        send(manager_pid, {:ok, temperature_of(location)})
      _ ->
       IO.puts "Error"
    end
    get_temperature()
  end

  def manager(cities \\ [], total) do
    receive do
      {:ok, temp} ->
        results = [ temp | cities ]
        if(Enum.count(results) == total) do
           send self(), :exit
        end
        manager(results, total)
      :exit ->
        IO.puts(cities |> Enum.sort |> Enum.join(", "))
      _ ->
        manager(cities, total)
    end
  end

  defp get_appid() do
    "bc0864ef50f0056c78dc59a5532d58e1"
  end

  defp get_endpoint(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{get_appid()}"
  end

  defp get_endpoint_by_zip_code(zip_code) do
    zip_code = URI.encode(zip_code)
    "http://api.openweathermap.org/data/2.5/weather?zip=#{zip_code},us&APPID=#{get_appid()}"
  end

  defp kelvin_to_celsius(kelvin) do
    (kelvin - 273.15) |> Float.round(1)
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

end
