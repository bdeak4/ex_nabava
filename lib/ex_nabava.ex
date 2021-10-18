defmodule ExNabava do
  @moduledoc """
  Documentation for `ExNabava`.
  """

  # Raspoloživo, isporuka odmah u trgovini
  @availability_in_stock 1

  # Raspoloživo, isporuka do 2 dana po uplati
  @availability_delayed 2

  # U dolasku, po narudžbi
  @availability_in_arrival 3

  # Raspoloživost potrebno provjeriti / Nije raspoloživo
  @availability_out_of_stock 4

  @doc """
  Returns search results.
  """
  def search(query, page, page_size, price_from, price_to, availability) do
    # TODO
  end

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
          api_url("stores")
          |> HTTPoison.get!()
          |> Map.get(:body)
          |> Jason.decode!()
          |> Map.get("stores")
          |> Map.new(fn s ->
            {s["id"],
             %{
               name: s["name"],
               logo: s["logo"],
               homepage: s["homepage"],
               emails:
                 if s["locations"] do
                   Enum.filter_map(
                     s["locations"],
                     fn l -> l["email"] != nil end,
                     fn l -> l["email"] end
                   )
                 else
                   []
                 end
             }}
          end)

        Agent.start_link(fn -> stores end, name: :stores)
        Agent.start_link(fn -> DateTime.utc_now() end, name: :stores_modified)
        stores
    end
  end

  defp api_url(path) do
    "https://www.nabava.net/api/3/mobile/json/" <> device_id() <> "/" <> path
  end

  defp device_id do
    Application.fetch_env!(:ex_nabava, :device_id)
  end
end
