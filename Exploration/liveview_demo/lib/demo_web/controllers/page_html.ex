defmodule DemoWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use DemoWeb, :html

  embed_templates "page_html/*"

  attr :path, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  def example_link(assigns) do
    ~H"""
    <a href={@path} class="group relative rounded-box px-4 py-3 text-sm leading-6">
      <span class="absolute inset-0 rounded-box bg-base-200 transition group-hover:bg-base-300"></span>
      <span class="relative block font-semibold">{@title}</span>
      <span class="relative block text-base-content/70">{@description}</span>
    </a>
    """
  end
end
