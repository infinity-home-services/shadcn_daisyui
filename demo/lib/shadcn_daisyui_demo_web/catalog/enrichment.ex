defmodule ShadcnDaisyuiDemoWeb.Catalog.Enrichment do
  @moduledoc """
  Design metadata - `specs`, `accessibility`, `swiftui`, `ios_status` - for
  catalog components, kept in per-group files separate from the base catalog.

  This separation means the (large) design metadata can be authored group by
  group without touching a component's examples, and each group file is an
  independent edit target. The maps here are merged into the matching base spec
  by slug in `Catalog.components/0`, then validated by `Catalog.Spec`.

  Button, Input, and Dialog carry their enrichment inline in `Catalog` as the
  worked examples; everything else is enriched here.
  """

  alias ShadcnDaisyuiDemoWeb.Catalog.Enrichment.{Core, MorePrimitives, Interactive, Extras}

  @doc "Map of slug => enrichment fields (a partial spec map merged onto the base)."
  def all do
    %{}
    |> Map.merge(Core.specs())
    |> Map.merge(MorePrimitives.specs())
    |> Map.merge(Interactive.specs())
    |> Map.merge(Extras.specs())
  end
end
