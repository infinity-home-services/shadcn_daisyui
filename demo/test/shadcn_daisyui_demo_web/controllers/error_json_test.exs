defmodule ShadcnDaisyuiDemoWeb.ErrorJSONTest do
  use ShadcnDaisyuiDemoWeb.ConnCase, async: true

  test "renders 404" do
    assert ShadcnDaisyuiDemoWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ShadcnDaisyuiDemoWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
