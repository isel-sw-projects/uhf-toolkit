package org.vaadin.example;

import com.vaadin.flow.component.html.Div;
import com.vaadin.flow.component.html.H1;
import com.vaadin.flow.component.html.Paragraph;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.flow.router.BeforeEvent;
import com.vaadin.flow.router.HasUrlParameter;
import com.vaadin.flow.router.Route;
import com.vaadin.flow.router.WildcardParameter;

/**
 * Dispatcher of the 18 BRHC examples in Vaadin Flow.
 * Route: /example/{name} - delegates to each example's constructor.
 *
 * Teaching note: in BRHC each example is an HTML file + data-* attributes;
 * in Vaadin each example is a Java class building the component tree
 * and receives updates by push over the same WebSocket.
 */
@Route("example")
public class ExampleView extends VerticalLayout implements HasUrlParameter<String> {

    @Override
    public void setParameter(BeforeEvent event, @WildcardParameter String example) {
        removeAll();
        String name = example.isEmpty() ? "index" : example;

        add(new H1(name));
        add(new Paragraph(DESCRIPTIONS.getOrDefault(name,
                "HtmlFlow-Datastar-Examples example reimplemented in Vaadin Flow.")));

        Div demo = new Div();
        demo.addClassName("demo-box");
        switch (name) {
            case "counter" -> Examples.counter(demo);
            case "counter-signals" -> Examples.counterSignals(demo);
            case "active-search" -> Examples.activeSearch(demo);
            case "click-to-edit" -> Examples.clickToEdit(demo);
            case "click-to-edit-signals" -> Examples.clickToEditSignals(demo);
            case "click-to-load" -> Examples.clickToLoad(demo);
            case "bulk-update" -> Examples.bulkUpdate(demo);
            case "delete-row" -> Examples.deleteRow(demo);
            case "edit-row" -> Examples.editRow(demo);
            case "inline-validation" -> Examples.inlineValidation(demo);
            case "signal-complex-domain" -> Examples.signalComplexDomain(demo);
            case "lazy-tabs" -> Examples.lazyTabs(demo);
            case "lazy-load" -> Examples.lazyLoad(demo);
            case "progress-bar" -> Examples.progressBar(demo);
            case "progressive-load" -> Examples.progressiveLoad(demo);
            case "infinite-scroll" -> Examples.infiniteScroll(demo);
            case "file-upload" -> Examples.fileUpload(demo);
            case "todo-mvc" -> Examples.todoMvc(demo);
            case "optimistic-actions" -> Examples.optimisticActions(demo);
            case "multi-client-counter" -> Examples.multiClientCounter(demo);
            case "deeplink-state", "deeplink-state/inactive/1", "deeplink-state/inactive/2",
                    "deeplink-state/active/1", "deeplink-state/active/2", "deeplink-state/all/1",
                    "deeplink-state/all/2" -> {
                String[] parts = name.split("/");
                // URL: example/deeplink-state[/filter/page] - state is read from the URL, as in
                // the
                String f = parts.length > 1 ? parts[1] : "active";
                int pg = parts.length > 2 ? Integer.parseInt(parts[2]) : 1;
                Examples.deeplinkState(demo, f, pg);
            }
            case "streaming-input" -> Examples.streamingInput(demo);
            case "large-list" -> Examples.largeList(demo);
            case "binary-payload" -> Examples.binaryPayload(demo);
            default -> demo.add(new Paragraph("Unknown example: " + name));
        }
        add(demo);
    }

    private static final java.util.Map<String, String> DESCRIPTIONS = java.util.Map.ofEntries(
            java.util.Map.entry("counter",
                    "In BRHC: data-init @get('/counter/events') opens SSE; here the state lives in the UI "
                            + "and push delivers the tree diff."),
            java.util.Map.entry("counter-signals",
                    "In BRHC: a count signal synchronised over SSE; here it is the same component - "
                            + "Vaadin push is already the server channel; there is no separate signal to type."),
            java.util.Map.entry("active-search",
                    "In BRHC: data-bind + data-on:input__debounce.200ms @get - the term travels in ?datastar=; "
                            + "here the ValueChangeListener filters on the server and push re-renders."),
            java.util.Map.entry("click-to-edit",
                    "In BRHC: fragments via @get/@put; here the 'editing' boolean switches the components."),
            java.util.Map.entry("click-to-edit-signals",
                    "In BRHC: data-bind + data-text update without fragment swapping; in Vaadin the "
                            + "fields already are server components."),
            java.util.Map.entry("click-to-load",
                    "In BRHC: ?datastar={offset,limit} returns patch-signals + patch-elements; here "
                            + "the offset is an AtomicInteger in the UI and every click appends rows."),
            java.util.Map.entry("bulk-update",
                    "In BRHC: a selections array in signals + a batch patch; here the checkboxes "
                            + "and the toggle button live in the same push circuit."),
            java.util.Map.entry("delete-row",
                    "In BRHC: @delete('/delete-row/{index}') + morphMode.remove; here removing "
                            + "is operating on a Java list - the remove morphology is delivered by the diff."),
            java.util.Map.entry("edit-row",
                    "In BRHC: @get edits the row (patch-signals + patch-elements) and @patch saves; "
                            + "here the editing_index boolean swaps Span<->TextField in the row."),
            java.util.Map.entry("inline-validation",
                    "In BRHC: @post per keystroke with debounce returns error fragments; here the "
                            + "ValueChangeListener validates with the same rules (email test@test.com, names >= 2)."),
            java.util.Map.entry("signal-complex-domain",
                    "In BRHC: nested signals ($person.name); here the nested object is a record - "
                            + "static typing replaces the signal path."),
            java.util.Map.entry("lazy-tabs",
                    "In BRHC: data-on:click @get('/lazy-tabs/{n}') returns the on-demand fragment; "
                            + "here the content is built in the tab's listener."),
            java.util.Map.entry("lazy-load",
                    "In BRHC: data-init @get waits 2s and emits patchElements; here the push arrives "
                            + "2s later via ui.access - the server pushes later."),
            java.util.Map.entry("progress-bar",
                    "In BRHC: an SSE stream of patchElements up to 100%; here it is a sequence of "
                            + "scheduled push(ui.access) calls."),
            java.util.Map.entry("progressive-load",
                    "In BRHC: sequential fragments (header->article->footer) on SSE; here three "
                            + "scheduled pushes fill three Divs."),
            java.util.Map.entry("infinite-scroll",
                    "In BRHC: data-on-intersect on a sentinel; the Flow Viritin free add-on "
                            + "brings the IntersectionObserver in plain Java - observing the sentinel is the same gesture."),
            java.util.Map.entry("file-upload",
                    "In BRHC: files as base64 in signals + a 1 MB limit; here the Upload "
                            + "does native multipart streaming - validation is setMaxFileSize."),
            java.util.Map.entry("todo-mvc",
                    "In BRHC: CRUD via @post/@patch/@delete with SSE; here everything is Java listeners."),
            java.util.Map.entry("optimistic-actions",
                    "In BRHC: pending badge via data-indicator and rollback via patch-elements; here "
                            + "pending is button state and rollback is re-assigning the value." +
                            " Item 3 always fails - the rollback stays visible."),
            java.util.Map.entry("multi-client-counter",
                    "In BRHC: a shared state flow with SSE for N clients; here MultiClientBus "
                            + "broadcasts over UI.sub - the push reaches every registered view."),
            java.util.Map.entry("deeplink-state",
                    "In BRHC: data-signals seeded from the URL + initial rows; here the server reads the "
                            + "URL in the dispatcher and builds the tree already in the right state."),
            java.util.Map.entry("streaming-input",
                    "In BRHC: an SSE stream of chunks with the input active in parallel; here 5 "
                            + "scheduled pushes run while the input listener stays active."),
            java.util.Map.entry("large-list",
                    "In BRHC: 500 <tr id> in one patch; here the ordered-list re-render "
                            + "preserves keys (the keyed-morph analogue)."),
            java.util.Map.entry("binary-payload",
                    "In BRHC: bytes in the @post body + digest in the patch; here the Upload handler "
                            + "reads the stream and computes the SHA-256 on the server."));
}