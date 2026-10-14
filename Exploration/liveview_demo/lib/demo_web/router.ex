defmodule DemoWeb.Router do
  use DemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", DemoWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Trace of the 18 HtmlFlow-Datastar-Examples examples in LiveView.
    live "/active-search", ActiveSearchLive
    live "/bulk-update", BulkUpdateLive
    live "/click-to-edit", ClickToEditLive
    live "/click-to-edit-signals", ClickToEditSignalsLive
    live "/click-to-load", ClickToLoadLive
    live "/counter", CounterLive
    live "/counter-signals", CounterSignalsLive
    live "/delete-row", DeleteRowLive
    live "/edit-row", EditRowLive
    live "/file-upload", FileUploadLive
    live "/infinite-scroll", InfiniteScrollLive
    live "/inline-validation", InlineValidationLive
    live "/lazy-load", LazyLoadLive
    live "/lazy-tabs", LazyTabsLive
    live "/progress-bar", ProgressBarLive
    live "/progressive-load", ProgressiveLoadLive
    live "/signal-complex-domain", SignalComplexDomainLive
    live "/todo-mvc", TodoMvcLive
    live "/optimistic-actions", OptimisticActionsLive
    live "/multi-client-counter", MultiClientCounterLive
    live "/deeplink-state", DeepLinkStateLive
    live "/streaming-input", StreamingInputLive
    live "/large-list", LargeListLive
    live "/binary-payload", BinaryPayloadLive
  end
end
