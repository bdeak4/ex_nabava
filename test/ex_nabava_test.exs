defmodule ExNabavaTest do
  use ExUnit.Case
  doctest ExNabava

  test "search_offers" do
    offers =
      ExNabava.search_offers(
        "playstation",
        1,
        10,
        ExNabava.const(:categories_all),
        ExNabava.const(:price_from_min),
        ExNabava.const(:price_to_max),
        [ExNabava.const(:availability_in_stock), ExNabava.const(:availability_delayed)],
        ExNabava.const(:order_cheaper_first)
      )

    assert length(offers["items"]) > 0
    assert Map.has_key?(Enum.at(offers["items"], 0), "id")
    assert Map.has_key?(Enum.at(offers["items"], 0), "productId")
    assert Map.has_key?(Enum.at(offers["items"], 0), "name")
    assert Map.has_key?(Enum.at(offers["items"], 0), "price")
    assert Map.has_key?(Enum.at(offers["items"], 0), "url")
  end

  test "search_products" do
    products = ExNabava.search_products("playstation", 10)

    assert length(products) > 0
    assert Map.has_key?(Enum.at(products, 0), "id")
    assert Map.has_key?(Enum.at(products, 0), "categoryId")
    assert Map.has_key?(Enum.at(products, 0), "name")
  end

  test "search_categories" do
    categories = ExNabava.search_categories("laptop", 10)

    assert length(categories) > 0
    assert Map.has_key?(Enum.at(categories, 0), "categoryId")
    assert Map.has_key?(Enum.at(categories, 0), "name")
    assert Map.has_key?(Enum.at(categories, 0), "url")
  end

  test "product" do
    product = ExNabava.product(11_895_295)

    assert length(product["offers"]) > 0
    assert Map.has_key?(product, "name")
    assert Map.has_key?(product, "image")
    assert Map.has_key?(Enum.at(product["offers"], 0), "id")
    assert Map.has_key?(Enum.at(product["offers"], 0), "storeId")
    assert Map.has_key?(Enum.at(product["offers"], 0), "name")
    assert Map.has_key?(Enum.at(product["offers"], 0), "url")
  end

  test "linked_products" do
    linked_products = ExNabava.linked_products(11_895_295)

    assert length(linked_products) > 0
    assert Map.has_key?(Enum.at(linked_products, 0), "id")
    assert Map.has_key?(Enum.at(linked_products, 0), "storeId")
    assert Map.has_key?(Enum.at(linked_products, 0), "name")
    assert Map.has_key?(Enum.at(linked_products, 0), "image")
  end

  test "categories" do
    categories = ExNabava.categories()

    assert Map.has_key?(Enum.at(categories, 0), "id")
    assert Map.has_key?(Enum.at(categories, 0), "name")
    assert Map.has_key?(Enum.at(categories, 0), "image")
  end

  test "stores" do
    stores = ExNabava.stores()
    assert length(Map.keys(stores)) > 0
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :id)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :name)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :logo)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :homepage)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :emails)
  end
end
