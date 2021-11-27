defmodule ExNabava do
  @moduledoc """
  ExNabava is unofficial elixir lib for accessing nabava.net public data.
  """

  def const,
    do: %{
      cache_max_age_in_seconds: 24 * 60 * 60,
      categories_all: -1,
      price_from_min: -1,
      price_to_max: 99999,

      # Raspoloživo, isporuka odmah u trgovini
      availability_in_stock: 1,
      # Raspoloživo, isporuka do 2 dana po uplati
      availability_delayed: 2,
      # U dolasku, po narudžbi
      availability_on_order: 3,
      # Nije raspoloživo
      availability_out_of_stock: 4,

      # Jeftiniji prvo
      order_cheaper_first: 2,
      # Skuplji prvo
      order_cheaper_last: 3,
      # Relevantniji prvo
      order_relevant_first: 0,
      # Relevantniji zadnji
      order_relevant_last: 1,
      # Naziv A-Z
      order_a_to_z: 6,
      # Naziv Z-A
      order_z_to_a: 7
    }

  @doc """
  Returns offer search results.
  """
  def search_offers(
        query,
        page,
        page_size,
        category_id,
        price_from,
        price_to,
        availability,
        order
      ) do
    qs = %{
      q: query,
      page: page,
      itemsByPage: page_size,
      availability: Enum.join(availability, ","),
      order: order
    }

    qs =
      if category_id != const().categories_all do
        Map.put(qs, :category, category_id)
      else
        qs
      end

    qs =
      if price_from != const().price_from_min do
        Map.put(qs, :priceFrom, price_from)
      else
        qs
      end

    qs =
      if price_to != const().price_to_max do
        Map.put(qs, :priceTo, price_to)
      else
        qs
      end

    (api_url("search") <> "?" <> URI.encode_query(qs))
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("searchResults")
  end

  @doc """
  Returns product search results.
  """
  def search_products(query, page_size) do
    qs = %{
      q: query,
      r: page_size
    }

    (api_url("search/autocomplete") <> "?" <> URI.encode_query(qs))
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("data")
    |> Enum.filter(fn p -> Map.get(p, "type") == 2 end)
  end

  @doc """
  Returns category search results.
  """
  def search_categories(query, page_size) do
    qs = %{
      q: query,
      r: page_size
    }

    (api_url("search/autocomplete") <> "?" <> URI.encode_query(qs))
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("data")
    |> Enum.filter(fn p -> Map.get(p, "type") == 3 end)
  end

  @doc """
  Returns product info and offers.
  """
  def product(id) do
    (api_url("product") <> "/#{id}")
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("product")
  end

  @doc """
  Returns products linked to product id.
  """
  def linked_products(id) do
    (api_url("product") <> "/#{id}/linkedproducts")
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("linkedProductsItems")
  end

  @doc """
  Returns (cached) list of categories.
  """
  def categories do
    try do
      date_modified = Agent.get(:categories_modified, & &1)
      cache_age_in_seconds = DateTime.diff(DateTime.utc_now(), date_modified)

      if cache_age_in_seconds > const().cache_max_age_in_seconds do
        exit("cache outdated")
      end

      Agent.get(:categories, & &1)
    catch
      :exit, _ ->
        categories =
          api_url("categories")
          |> HTTPoison.get!()
          |> Map.get(:body)
          |> Jason.decode!()
          |> Map.get("categories")

        Agent.start_link(fn -> categories end, name: :categories)
        Agent.start_link(fn -> DateTime.utc_now() end, name: :categories_modified)
        categories
    end
  end

  @doc """
  Returns (cached) list of stores.
  """
  def stores do
    try do
      date_modified = Agent.get(:stores_modified, & &1)
      cache_age_in_seconds = DateTime.diff(DateTime.utc_now(), date_modified)

      if cache_age_in_seconds > const().cache_max_age_in_seconds do
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
