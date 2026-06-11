defmodule ShadcnDaisyuiDemoWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ShadcnDaisyuiDemoWeb, :html

  import ShadcnDaisyuiDemoWeb.DocsComponents

  embed_templates "page_html/*"
end
