defmodule ExNabava do
  @moduledoc """
  ExNabava is unofficial elixir lib for accessing nabava.net public data.
  """

  @doc """
  Returns constant

  List of constants:

  - `:cache_max_age_in_seconds`
  - `:categories_all`
  - `:price_from_min`
  - `:price_to_max`
  - `:availability_in_stock` (Raspoloživo, isporuka odmah u trgovini)
  - `:availability_delayed` (Raspoloživo, isporuka do 2 dana po uplati)
  - `:availability_on_order` (U dolasku, po narudžbi)
  - `:availability_out_of_stock` (Nije raspoloživo)
  - `:order_cheaper_first` (Jeftiniji prvo)
  - `:order_cheaper_last` (Skuplji prvo)
  - `:order_relevant_first` (Relevantniji prvo)
  - `:order_relevant_last` (Relevantniji zadnji)
  - `:order_a_to_z` (Naziv A-Z)
  - `:order_z_to_a` (Naziv Z-A)
  """
  def const(:cache_max_age_in_seconds), do: 24 * 60 * 60
  def const(:categories_all), do: -1
  def const(:price_from_min), do: -1
  def const(:price_to_max), do: 99999
  def const(:availability_in_stock), do: 1
  def const(:availability_delayed), do: 2
  def const(:availability_on_order), do: 3
  def const(:availability_out_of_stock), do: 4
  def const(:order_cheaper_first), do: 2
  def const(:order_cheaper_last), do: 3
  def const(:order_relevant_first), do: 0
  def const(:order_relevant_last), do: 1
  def const(:order_a_to_z), do: 6
  def const(:order_z_to_a), do: 7

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
      if category_id != const(:categories_all) do
        Map.put(qs, :category, category_id)
      else
        qs
      end

    qs =
      if price_from != const(:price_from_min) do
        Map.put(qs, :priceFrom, price_from)
      else
        qs
      end

    qs =
      if price_to != const(:price_to_max) do
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

      if cache_age_in_seconds > const(:cache_max_age_in_seconds) do
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

      if cache_age_in_seconds > const(:cache_max_age_in_seconds) do
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
