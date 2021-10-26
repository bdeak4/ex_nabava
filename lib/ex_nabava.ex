defmodule ExNabava do
  @moduledoc """
  Documentation for `ExNabava`.
  """

  @doc """
  ...
  """
  def store_products() do
  end

  # Raspoloživo, isporuka odmah u trgovini
  @availability_in_stock 1

  # Raspoloživo, isporuka do 2 dana po uplati
  @availability_delayed 2

  # U dolasku, po narudžbi
  @availability_on_order 3

  # Nije raspoloživo
  @availability_out_of_stock 4

  def availability_in_stock, do: @availability_in_stock
  def availability_delayed, do: @availability_delayed
  def availability_on_order, do: @availability_on_order
  def availability_out_of_stock, do: @availability_out_of_stock

  # Jeftiniji prvo
  @order_cheaper_first 2

  # Skuplji prvo
  @order_cheaper_last 3

  # Relevantniji prvo
  @order_relevant_first 0

  # Relevantniji zadnji
  @order_relevant_last 1

  # Naziv A-Z
  @order_a_to_z 6

  # Naziv Z-A
  @order_z_to_a 7

  def order_cheaper_first, do: @order_cheaper_first
  def order_cheaper_last, do: @order_cheaper_last
  def order_relevant_first, do: @order_relevant_first
  def order_relevant_last, do: @order_relevant_last
  def order_a_to_z, do: @order_a_to_z
  def order_z_to_a, do: @order_z_to_a

  @doc """
  Returns search results.
  """
  def search(query, page, page_size, price_from, price_to, availability, order) do
    qs = %{
      q: query,
      page: page,
      itemsByPage: page_size,
      priceFrom: price_from,
      priceTo: price_to,
      availability: Enum.join(availability, ","),
      order: order
    }

    IO.puts(api_url("search") <> "?" <> URI.encode_query(qs))
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
               id: s["id"],
               name: s["name"],
               logo: s["logo"],
               homepage: s["homepage"],
               emails:
                 if s["locations"] do
                   Enum.filter(
                     Enum.map(s["locations"], fn l -> l["email"] end),
                     fn e -> e != nil end
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
