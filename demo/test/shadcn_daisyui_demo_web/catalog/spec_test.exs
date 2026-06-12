defmodule ShadcnDaisyuiDemoWeb.Catalog.SpecTest do
  use ExUnit.Case, async: true

  alias ShadcnDaisyuiDemoWeb.Catalog
  alias ShadcnDaisyuiDemoWeb.Catalog.Spec

  @valid %{
    slug: "widget",
    title: "Widget",
    description: "A test widget.",
    examples: [%{title: "Default", code: "<div class=\"widget\"></div>"}]
  }

  describe "new!/1 with valid data" do
    test "returns a %Spec{} with required fields" do
      spec = Spec.new!(@valid)
      assert %Spec{} = spec
      assert spec.slug == "widget"
      assert spec.hook == false
      assert spec.props == []
    end

    test "accepts an already-built %Spec{} and re-validates it" do
      spec = Spec.new!(@valid)
      assert Spec.new!(spec) == spec
    end

    test "accepts the optional guidance / props / hook fields" do
      spec =
        Spec.new!(
          Map.merge(@valid, %{
            hook: true,
            guidance: %{use_when: ["a"], avoid_when: ["b"], sizing: "x"},
            props: [%{name: "variant", type: "a | b", default: "a"}]
          })
        )

      assert spec.hook == true
      assert spec.guidance.use_when == ["a"]
    end
  end

  describe "new!/1 rejects malformed specs" do
    test "missing a required field" do
      assert_raise ArgumentError, ~r/widget/, fn ->
        Spec.new!(Map.delete(@valid, :description))
      end
    end

    test "an unknown / typo'd key (names the slug)" do
      assert_raise ArgumentError, ~r/"widget"/, fn ->
        Spec.new!(Map.put(@valid, :guidence, %{}))
      end
    end

    test "no examples" do
      assert_raise ArgumentError, ~r/at least one example/, fn ->
        Spec.new!(Map.put(@valid, :examples, []))
      end
    end

    test "an example missing :code" do
      assert_raise ArgumentError, ~r/needs non-empty :code/, fn ->
        Spec.new!(Map.put(@valid, :examples, [%{title: "X"}]))
      end
    end

    test "an unknown guidance key" do
      assert_raise ArgumentError, ~r/unknown guidance key/, fn ->
        Spec.new!(Map.put(@valid, :guidance, %{use_when: ["a"], why: "nope"}))
      end
    end

    test "a prop without a type" do
      assert_raise ArgumentError, ~r/needs a :type/, fn ->
        Spec.new!(Map.put(@valid, :props, [%{name: "variant"}]))
      end
    end

    test "an invalid ios_status" do
      assert_raise ArgumentError, ~r/ios_status/, fn ->
        Spec.new!(Map.put(@valid, :ios_status, :someday))
      end
    end
  end

  describe "the real catalog" do
    test "every component builds into a valid %Spec{}" do
      # Catalog.components/0 runs Spec.new!/1 on all 77 entries; an invalid spec
      # raises here, named by slug.
      for {slug, spec} <- Catalog.components() do
        assert %Spec{} = spec
        assert spec.slug == slug
      end
    end
  end
end
