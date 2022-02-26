defmodule ExNabava do
  @moduledoc """
  ExNabava is unofficial elixir lib for accessing nabava.net public data.
  """

  @doc """
  Returns constant

  List of constants:

  - `:categories_all`
  - `:price_from_min`
  - `:price_to_max`
  - `:availability_in_stock` (Raspoloživo, isporuka odmah u trgovini)
  - `:availability_delayed` (Raspoloživo, isporuka do 2 dana po uplati)
  - `:availability_on_order` (U dolasku, po narudžbi)
  - `:availability_out_of_stock` (Nije raspoloživo)
  - `:sort_cheaper_first` (Jeftiniji prvo)
  - `:sort_cheaper_last` (Skuplji prvo)
  - `:sort_relevant_first` (Relevantniji prvo)
  - `:sort_relevant_last` (Relevantniji zadnji)
  - `:sort_a_to_z` (Naziv A-Z)
  - `:sort_z_to_a` (Naziv Z-A)
  """
  def const(:categories_all), do: -1
  def const(:price_from_min), do: -1
  def const(:price_to_max), do: 99999
  def const(:availability_in_stock), do: 1
  def const(:availability_delayed), do: 2
  def const(:availability_on_order), do: 3
  def const(:availability_out_of_stock), do: 4
  def const(:sort_cheaper_first), do: 2
  def const(:sort_cheaper_last), do: 3
  def const(:sort_relevant_first), do: 0
  def const(:sort_relevant_last), do: 1
  def const(:sort_a_to_z), do: 6
  def const(:sort_z_to_a), do: 7

  @doc """
  Returns offer search results
  """
  def search_offers(
        query,
        page,
        page_size,
        category_id,
        price_from,
        price_to,
        availabilities,
        sort
      ) do
    qs =
      %{q: query}
      |> maybe_put(:page, page)
      |> maybe_put(:itemsByPage, page_size)
      |> maybe_put(:order, sort)
      |> maybe_put(Enum.any?(availabilities), :availability, Enum.join(availabilities, ","))
      |> maybe_put(category_id != const(:categories_all), :category, category_id)
      |> maybe_put(price_from != const(:price_from_min), :priceFrom, price_from)
      |> maybe_put(price_to != const(:price_to_max), :priceTo, price_to)
      |> URI.encode_query()

    get_resp("search?" <> qs)
    |> Map.get("searchResults")
  end

  @doc """
  Returns product search results
  """
  def search_products(query, page_size) do
    qs =
      %{q: query}
      |> maybe_put(:r, page_size)
      |> URI.encode_query()

    get_resp("search/autocomplete?" <> qs)
    |> Map.get("data")
    |> Enum.filter(fn p -> Map.get(p, "type") == 2 end)
  end

  @doc """
  Returns category search results
  """
  def search_categories(query, page_size) do
    qs =
      %{q: query}
      |> maybe_put(:r, page_size)
      |> URI.encode_query()

    get_resp("search/autocomplete?" <> qs)
    |> Map.get("data")
    |> Enum.filter(fn p -> Map.get(p, "type") == 3 end)
  end

  @doc """
  Returns product info and offers
  """
  def product(nil), do: %{}

  def product(id) do
    get_resp("product/#{id}")
    |> Map.get("product")
  end

  @doc """
  Returns products linked to product id
  """
  def linked_products(id) do
    get_resp("product/#{id}/linkedproducts")
    |> Map.get("linkedProductsItems")
  end

  @doc """
  Returns list of categories
  """
  def categories do
    get_resp("categories")
    |> Map.get("categories")
  end

  @doc """
  Returns list of stores
  """
  def stores do
    get_resp("stores")
    |> Map.get("stores")
  end

  @doc """
  Returns cached list of stores
  """
  def stores_cached do
    try do
      stores_modified = Agent.get(:stores_modified, & &1)
      cache_age_in_seconds = DateTime.diff(DateTime.utc_now(), stores_modified)
      one_day_in_seconds = 60 * 60 * 24

      if cache_age_in_seconds > one_day_in_seconds do
        exit("cache outdated")
      end

      Agent.get(:stores, & &1)
    catch
      :exit, _ ->
        stores = stores()
        Agent.start_link(fn -> stores end, name: :stores)
        Agent.start_link(fn -> DateTime.utc_now() end, name: :stores_modified)
        stores
    end
  end

  @doc """
  Returns store info
  """
  def store(nil), do: %{}

  def store(id) do
    stores_cached()
    |> Enum.find(%{}, fn s -> s["id"] == id end)
  end

  defp get_resp(path) do
    api_url(path)
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end

  defp api_url(path) do
    "https://www.na" <>
      "bava.net/ap" <>
      "i/3/mobi" <>
      "le/json/" <>
      Application.fetch_env!(:ex_nabava, :device_id) <>
      "/" <> path
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
  defp maybe_put(map, false, _key, _value), do: map
  defp maybe_put(map, true, key, value), do: maybe_put(map, key, value)
end
