defmodule ExNabava do
  @moduledoc """
  Documentation for `ExNabava`.
  """

  @cache_max_age_in_seconds 24 * 60 * 60

  @doc """
  Returns (cached) list of stores.
  """
  def stores do
    try do
      date_modified = Agent.get(:stores_modified, & &1)
      cache_age_in_seconds = DateTime.diff(DateTime.utc_now(), date_modified)

      if cache_age_in_seconds > @cache_max_age_in_seconds do
        exit("cache outdated")
      end

      Agent.get(:stores, & &1)
    catch
      :exit, _ ->
        stores =
          (api_url() <> "/stores")
          |> HTTPoison.get!()
          |> Map.get(:body)
          |> Jason.decode!()
          |> Map.get("stores")
          |> Map.new(fn s -> {s["id"], s} end)

        Agent.start_link(fn -> stores end, name: :stores)
        Agent.start_link(fn -> DateTime.utc_now() end, name: :stores_modified)
        stores
    end
  end

  defp api_url do
    "https://www.nabava.net/api/3/mobile/json/" <> device_id()
  end

  defp device_id do
    Application.fetch_env!(:ex_nabava, :device_id)
  end
end
