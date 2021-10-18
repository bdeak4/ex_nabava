defmodule ExNabavaTest do
  use ExUnit.Case
  doctest ExNabava

  test "stores" do
    stores = ExNabava.stores()
    assert length(Map.keys(stores)) > 0
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :name)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :logo)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :homepage)
    assert Map.has_key?(stores[List.first(Map.keys(stores))], :emails)
  end
end
