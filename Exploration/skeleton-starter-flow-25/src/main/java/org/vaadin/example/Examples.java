package org.vaadin.example;

import com.vaadin.flow.component.Key;
import com.vaadin.flow.component.UI;
import com.vaadin.flow.component.button.Button;
import com.vaadin.flow.component.checkbox.Checkbox;
import com.vaadin.flow.component.html.Div;
import com.vaadin.flow.component.html.H2;
import com.vaadin.flow.component.html.ListItem;
import com.vaadin.flow.component.html.Paragraph;
import com.vaadin.flow.component.html.Span;
import com.vaadin.flow.component.html.UnorderedList;
import com.vaadin.flow.component.orderedlayout.HorizontalLayout;
import com.vaadin.flow.component.progressbar.ProgressBar;
import com.vaadin.flow.router.QueryParameters;
import com.vaadin.flow.component.textfield.TextField;
import com.vaadin.flow.component.upload.Upload;
import com.vaadin.flow.data.value.ValueChangeMode;

import java.io.IOException;
import org.slf4j.LoggerFactory;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/**
 * BRHC example implementations in Vaadin Flow - one static method per example,
 * each building its portion of the component tree into the received Div.
 */
final class Examples {

    private static final String AGENT_LABEL = "Agent ";

    private Examples() {
    }

    private record Contact(String first, String last) {
    }

    private static final List<Contact> CONTACTS = List.of(
            new Contact("Abraham", "Altenwerth"), new Contact("Adan", "Padberg"),
            new Contact("Aiden", "Haley"), new Contact("Alec", "Kris"),
            new Contact("Alfredo", "Nitzsche"), new Contact("Alisha", "Rogahn"),
            new Contact("Alvah", "Bins"), new Contact("Anabel", "Lehner"),
            new Contact("Angela", "Swift"), new Contact("Annamarie", "Rippin"));

    private static List<String> seedUsers() {
        List<String> users = new ArrayList<>();
        for (int i = 1; i <= 5; i++) {
            users.add("User " + i);
        }
        return users;
    }

    private static void schedule(Div host, long ms, Runnable r) {
        CompletableFuture.delayedExecutor(ms, TimeUnit.MILLISECONDS)
                .execute(() -> push(host, r));
    }

    // ---- counter: data-init @get(events) + @post(increment/decrement) ----
    static void counter(Div demo) {
        AtomicInteger count = new AtomicInteger();
        Span label = new Span("0");
        // NOTE: the label has to be IN the tree - interpolating the text once
        // ("Current count: " + label.getText()) freezes the initial value.
        Paragraph p = new Paragraph("Current count: ");
        p.add(label);
        Button inc = new Button("Increment", e -> label.setText(String.valueOf(count.incrementAndGet())));
        Button dec = new Button("Decrement", e -> label.setText(String.valueOf(count.decrementAndGet())));
        demo.add(p, new HorizontalLayout(inc, dec));
    }

    /**
     * counter-signals: in Vaadin the variant collapses - state already lives on the
     * server
     * and push synchronises it; there is no distinct local signal to type.
     */
    static void counterSignals(Div demo) {
        counter(demo);
    }

    // ---- active-search: data-bind + data-on:input__debounce.200ms @get ----
    static void activeSearch(Div demo) {
        TextField search = new TextField("Search...");
        UnorderedList rows = new UnorderedList();
        Runnable refresh = () -> {
            rows.removeAll();
            String term = search.getValue().toLowerCase();
            for (Contact c : CONTACTS) {
                if (term.isEmpty()
                        || c.first().toLowerCase().contains(term)
                        || c.last().toLowerCase().contains(term)) {
                    rows.add(new ListItem(c.first() + " " + c.last()));
                }
            }
        };
        // debounce analogous to data-on:input__debounce.200ms
        search.setValueChangeMode(ValueChangeMode.LAZY);
        search.setValueChangeTimeout(200);
        search.addValueChangeListener(e -> refresh.run());
        refresh.run();
        demo.add(search, rows);
    }

    // ---- click-to-edit: @get/@put fragments vs component switching ----
    static void clickToEdit(Div demo) {
        AtomicReference<String> first = new AtomicReference<>("John");
        AtomicReference<String> last = new AtomicReference<>("Doe");
        Div container = new Div();
        AtomicReference<Runnable> viewMode = new AtomicReference<>();

        Runnable editMode = () -> {
            container.removeAll();
            TextField f = new TextField("First", first.get());
            TextField l = new TextField("Last", last.get());
            container.add(f, l, new Button("Submit", ev -> {
                first.set(f.getValue());
                last.set(l.getValue());
                viewMode.get().run();
            }));
        };
        viewMode.set(() -> {
            container.removeAll();
            container.add(new H2(first.get() + " " + last.get()),
                    new Button("Edit", e -> editMode.run()));
        });
        viewMode.get().run();
        demo.add(container);
    }

    /**
     * click-to-edit-signals: variant collapses, identical to the base (state is
     * Java).
     */
    static void clickToEditSignals(Div demo) {
        clickToEdit(demo);
    }

    // ---- click-to-load: @@get('/more') offset/limit ----
    static void clickToLoad(Div demo) {
        UnorderedList list = new UnorderedList();
        AtomicInteger offset = new AtomicInteger(5);
        for (int i = 1; i <= 5; i++) {
            list.add(new ListItem(AGENT_LABEL + i));
        }
        AtomicReference<Button> moreRef = new AtomicReference<>();
        Button more = new Button("Load More Agents", e -> {
            int o = offset.getAndAdd(5);
            for (int i = o + 1; i <= o + 5; i++) {
                list.add(new ListItem(AGENT_LABEL + i));
            }
            if (o + 5 >= 30) {
                moreRef.get().setEnabled(false);
            }
        });
        moreRef.set(more);
        demo.add(list, more);
    }

    // ---- bulk-update: data-bind:selections + @@put (bulk activate) ----
    static void bulkUpdate(Div demo) {
        List<Checkbox> boxes = new ArrayList<>();
        for (String u : seedUsers()) {
            boxes.add(new Checkbox(u));
        }
        Span feedback = new Span();
        Button activate = new Button("Activate Selected", e -> {
            long n = boxes.stream().filter(Checkbox::getValue).count();
            feedback.setText(n + " user(s) activated - the mutation runs on the server.");
        });
        demo.add(feedback, activate);
        for (Checkbox b : boxes) {
            demo.add(b);
        }
    }

    // ---- delete-row: confirm(...) && @@delete ----
    static void deleteRow(Div demo) {
        UnorderedList rows = new UnorderedList();
        for (String u : seedUsers()) {
            ListItem item = new ListItem(new Span(u + " "));
            Button del = new Button("Delete",
                    e -> item.getParent().ifPresent(p -> p.getElement().removeChild(item.getElement())));
            item.add(del);
            rows.add(item);
        }
        demo.add(rows);
    }

    // ---- edit-row: data-signals:_editing + @@get/@@put ----
    static void editRow(Div demo) {
        UnorderedList rows = new UnorderedList();
        for (String u : seedUsers()) {
            ListItem item = new ListItem();
            AtomicReference<Button> editRef = new AtomicReference<>();
            Button edit = new Button("Edit", e -> {
                TextField tf = new TextField();
                tf.setValue(u);
                Button save = new Button("Save", ev -> {
                    item.removeAll();
                    item.add(new Span(tf.getValue() + " "), editRef.get());
                });
                item.removeAll();
                item.add(tf, save);
            });
            editRef.set(edit);
            item.add(new Span(u + " "), edit);
            rows.add(item);
        }
        demo.add(rows);
    }

    // ---- inline-validation: keydown debounce 500ms @@post(validate) ----
    static void inlineValidation(Div demo) {
        TextField email = new TextField("Email");
        email.setValueChangeMode(ValueChangeMode.LAZY);
        email.setValueChangeTimeout(500);
        Span err = new Span();
        email.addValueChangeListener(
                e -> err.setText("test@test.com".equals(email.getValue()) ? "Email already registered" : ""));
        demo.add(email, err);
    }

    // ---- signal-complex-domain: {person:{name,age}} aninhado ----
    static void signalComplexDomain(Div demo) {
        record Person(String name, int age) {
        }
        AtomicReference<Person> person = new AtomicReference<>(new Person("John", 30));
        Span label = new Span();
        Runnable refresh = () -> label.setText(person.get().name() + " - " + person.get().age());
        refresh.run();
        demo.add(label,
                new Button("Increase Age", e -> {
                    Person p = person.get();
                    person.set(new Person(p.name(), p.age() + 1));
                    refresh.run();
                }));
    }

    // ---- lazy-tabs: @@get('/lazy-tabs/{n}') on-demand ----
    static void lazyTabs(Div demo) {
        HorizontalLayout tabs = new HorizontalLayout();
        Div content = new Div();
        for (int n = 1; n <= 3; n++) {
            final int tab = n;
            tabs.add(new Button("Tab " + n, e -> {
                content.removeAll();
                content.add(new Paragraph("Tab " + tab + " content - built on demand."));
            }));
        }
        demo.add(tabs, content);
    }

    // ---- lazy-load: patchElements after 2s on SSE -> ui.access 2s later ----
    static void lazyLoad(Div demo) {
        Div content = new Div(new Paragraph("Loading deferred content (2s)"));
        demo.add(content);
        CompletableFuture.delayedExecutor(2, TimeUnit.SECONDS)
                .execute(() -> push(demo, () -> {
                    content.removeAll();
                    content.add(new Paragraph("Heavy content loaded (push via ui.access)."));
                }));
    }

    /**
     * Pushes an update to the UI from a background thread - the analogue of the
     * BRHC server
     * emitting patchElements on SSE. ifPresent fails silently
     * when the UI no longer exists (navigation); the log keeps the case visible.
     */
    private static void push(Div host, Runnable update) {
        host.getUI().ifPresentOrElse(
                ui -> ui.access((com.vaadin.flow.server.Command) update::run),
                () -> LoggerFactory.getLogger(Examples.class).info("push ignored: UI no longer exists"));
    }

    // ---- progress-bar: SSE stream of patches -> sequence of pushes ----
    static void progressBar(Div demo) {
        ProgressBar bar = new ProgressBar(0, 100, 0);
        Span label = new Span("0%");
        demo.add(bar, label);
        // A single scheduled task increments the progress at each step - mirroring
        // BRHC's SSE stream, each setValue is pushed through ui.access.
        AtomicInteger value = new AtomicInteger();
        Runnable tick = new Runnable() {
            @Override
            public void run() {
                int v = value.addAndGet(5);
                push(demo, () -> {
                    bar.setValue(v);
                    label.setText(v + "%");
                });
                if (v < 100) {
                    CompletableFuture.delayedExecutor(300, TimeUnit.MILLISECONDS)
                            .execute(this);
                }
            }
        };
        CompletableFuture.delayedExecutor(300, TimeUnit.MILLISECONDS).execute(tick);
    }

    // ---- progressive-load: fragmentos sequenciais (header→article→footer) ----
    static void progressiveLoad(Div demo) {
        Div header = new Div();
        Div article = new Div();
        Div footer = new Div();
        demo.add(header, article, footer);
        schedule(demo, 400, () -> header.setText("Progressive Load"));
        schedule(demo, 1000, () -> article.setText("Este artigo chegou por partes."));
        schedule(demo, 1600, () -> footer.setText("End of deferred content."));
    }

    // ---- infinite-scroll: data-on-intersect (sentinela) ----
    static void infiniteScroll(Div demo) {
        UnorderedList list = new UnorderedList();
        AtomicInteger offset = new AtomicInteger(5);
        for (int i = 1; i <= 5; i++) {
            list.add(new ListItem(AGENT_LABEL + i));
        }
        // The Flow Viritin add-on brings the IntersectionObserver in plain Java:
        // observing the sentinel is the direct analogue of BRHC's
        // data-on-intersect="@get('/infinite-scroll/more')" - the server appends
        // the next rows when the sentinel enters the viewport.
        Div sentinel = new Div();
        sentinel.setHeight("1px");
        org.vaadin.firitin.util.IntersectionObserver
                .of(UI.getCurrent())
                .withRootMargin("100px")
                .observe(sentinel, entry -> {
                    if (entry.isIntersecting()) {
                        int o = offset.getAndAdd(5);
                        push(demo, () -> {
                            for (int i = o + 1; i <= o + 5; i++) {
                                list.add(new ListItem(AGENT_LABEL + i));
                            }
                        });
                    }
                });
        demo.add(list, sentinel);
    }

    // ---- file-upload: data-bind:files base64 + limite 1MB ----
    static void fileUpload(Div demo) {
        Upload upload = new Upload();
        upload.setMaxFileSize(1024 * 1024);
        // Sem handler o servidor rejeita o POST com 500; receber e descartar
        // keeps the trace focused on BRHC's (1 MB) validation flow.
        // On the streams API (UploadHandler) the component never fires FinishedEvent/
        // SucceededEvent - esses pertencem ao fluxo antigo Receiver - por isso o
        // outcome is recorded here, inside the handler itself: it is the analogue of
        // the SSE fragment BRHC returns after validation. Files above
        // maxFileSize are rejected on the client (FileRejectedListener, below).
        upload.setUploadHandler(event -> {
            try (InputStream in = event.getInputStream()) {
                in.transferTo(OutputStream.nullOutputStream());
                push(demo, () -> demo.add(new Paragraph(event.getFileName() + " - ✔ aceite")));
            } catch (IOException e) {
                push(demo, () -> demo.add(new Paragraph(event.getFileName() + " - ✘ erro")));
            }
        });
        upload.addFileRejectedListener(e -> demo.add(new Paragraph("✘ rejeitado: " + e.getErrorMessage())));
        demo.add(upload);
    }

    // ---- optimistic-actions: pending -> confirmation/rollback (rollback visible)
    // ----
    private record Item(int id, String label, int value, boolean pending, boolean failed) {
    }

    static void optimisticActions(Div demo) {

        List<Item> items = new ArrayList<>(List.of(
                new Item(0, "Item 1", 10, false, false),
                new Item(1, "Item 2", 20, false, false),
                // Item 3 falha sempre - alimenta o caminho de rollback (igual ao Kotlin).
                new Item(2, "Item 3", 30, false, true),
                new Item(3, "Item 4", 40, false, false)));

        com.vaadin.flow.component.html.Paragraph error = new com.vaadin.flow.component.html.Paragraph();
        error.setVisible(false);
        error.getStyle().set("color", "var(--lumo-error-color)");

        com.vaadin.flow.component.orderedlayout.VerticalLayout box = new com.vaadin.flow.component.orderedlayout.VerticalLayout();

        for (Item it : items) {
            com.vaadin.flow.component.html.Span val = new com.vaadin.flow.component.html.Span(
                    String.valueOf(it.value()));
            com.vaadin.flow.component.button.Button b = new com.vaadin.flow.component.button.Button("+10");
            b.addClickListener(e -> {
                b.setText("pending…");
                b.setEnabled(false);
                // the scheduled callback does the id lookup, the rollback/confirm
                // branch and the button/label restore (see resolvePending below)
                schedule(demo, 600, () -> resolvePending(items, it, val, b, error));
            });
            com.vaadin.flow.component.html.ListItem li = new com.vaadin.flow.component.html.ListItem(
                    new com.vaadin.flow.component.html.Span(it.label() + " - "), val, b);
            com.vaadin.flow.component.html.UnorderedList list = lastUnorderedList(box);
            if (list == null) {
                list = new com.vaadin.flow.component.html.UnorderedList();
                box.add(list);
            }
            list.add(li);
        }

        demo.add(error, box);
    }

    // ---- multi-client-counter: um valor, N clientes (broadcast por UI) ----
    static void multiClientCounter(Div demo) {
        com.vaadin.flow.component.html.Span label = new com.vaadin.flow.component.html.Span("0");

        com.vaadin.flow.component.button.Button inc = new com.vaadin.flow.component.button.Button(
                "Increment (all clients)",
                e -> {
                    int v = MultiClientBus.increment();
                    MultiClientBus.broadcast(v);
                });

        demo.add(new com.vaadin.flow.component.html.Paragraph("Shared value: "), label, inc,
                new com.vaadin.flow.component.html.Paragraph(
                        "Open a second window at /example/multi-client-counter - the values synchronise."));

        // subscribe the current view (the Kotlin example's data-init @get(events))
        MultiClientBus.subscribe(v -> push(demo, () -> label.setText(String.valueOf(v))));
    }

    // ---- deeplink-state: a URL como fonte do estado ----
    static void deeplinkState(Div demo, String filter, int pageN) {
        com.vaadin.flow.component.html.Paragraph p = new com.vaadin.flow.component.html.Paragraph(
                "The URL reflects the state: filter=" + filter + ", page=" + pageN
                        + " - reloading/connecting directly restores the same view.");
        com.vaadin.flow.component.html.UnorderedList list = new com.vaadin.flow.component.html.UnorderedList();
        for (int c : pagedContacts(filter, pageN)) {
            list.add(new com.vaadin.flow.component.html.ListItem(
                    "Contact " + c + " - " + (c % 3 == 0 ? "inactive" : "active")));
        }
        demo.add(p, list);
    }

    private static void resolvePending(List<Item> items, Item it,
            com.vaadin.flow.component.html.Span val,
            com.vaadin.flow.component.button.Button b,
            com.vaadin.flow.component.html.Paragraph error) {
        int idx = indexOfItem(items, it.id());
        Item current = items.get(idx);
        if (current.failed()) {
            error.setText("Server refused: simulated failure (rollback)");
            error.setVisible(true);
        } else {
            Item updated = new Item(it.id(), it.label(), current.value() + 10, false, false);
            items.set(idx, updated);
            val.setText(String.valueOf(updated.value()));
            error.setVisible(false);
        }
        b.setText("+10");
        b.setEnabled(true);
    }

    private static int indexOfItem(List<Item> items, int id) {
        for (int i = 0; i < items.size(); i++) {
            if (items.get(i).id() == id) {
                return i;
            }
        }
        return -1;
    }

    private static com.vaadin.flow.component.html.UnorderedList lastUnorderedList(
            com.vaadin.flow.component.HasComponents box) {
        if (box.getComponentCount() == 0) {
            return null;
        }
        com.vaadin.flow.component.Component last = box.getComponentAt(box.getComponentCount() - 1);
        return last instanceof com.vaadin.flow.component.html.UnorderedList ul ? ul : null;
    }

    private static List<Integer> pagedContacts(String filter, int page) {
        List<Integer> contacts = new ArrayList<>();
        for (int i = 1; i <= 12; i++) {
            boolean excluded = ("active".equals(filter) && i % 3 == 0)
                    || ("inactive".equals(filter) && i % 3 != 0);
            if (!excluded) {
                contacts.add(i);
            }
        }
        int perPage = 4;
        int from = (page - 1) * perPage;
        if (from >= contacts.size())
            return List.of();
        return contacts.subList(from, Math.min(from + perPage, contacts.size()));
    }

    // ---- streaming-input: chunks + input activo em paralelo ----
    static void streamingInput(Div demo) {
        com.vaadin.flow.component.html.Div window = new com.vaadin.flow.component.html.Div();
        com.vaadin.flow.component.html.Div messages = new com.vaadin.flow.component.html.Div();
        TextField input = new TextField("type during the stream...");
        com.vaadin.flow.component.button.Button send = new com.vaadin.flow.component.button.Button("Send");

        // the stream runs in parallel with the input - pushes are scheduled
        for (int i = 0; i < 5; i++) {
            final long delay = 800L * (i + 1);
            final String text = i < 4 ? "received: chunk " + (char) ('A' + i) : "stream complete.";
            schedule(demo, delay, () -> window.add(new com.vaadin.flow.component.html.Paragraph(text)));
        }

        // EAGER: the value reaches the server on every keystroke (the analogue of the
        // Kotlin example, which sends the signal in the POST); the message comes from
        // server state.
        input.setValueChangeMode(ValueChangeMode.EAGER);
        send.addClickListener(e -> {
            String v = input.getValue();
            messages.add(new com.vaadin.flow.component.html.Paragraph(
                    "mensagem recebida durante o stream: " + (v == null || v.isBlank() ? "(vazia)" : v)));
        });
        demo.add(window, new HorizontalLayout(input, send), messages);
    }

    // ---- large-list: 500 rows keyed + reorder ----
    static void largeList(Div demo) {
        record Row(int id, String label) {
        }

        List<Row> rows = new ArrayList<>();
        for (int i = 1; i <= 500; i++) {
            rows.add(new Row(i, "Row " + i));
        }

        com.vaadin.flow.component.button.Button reorder = new com.vaadin.flow.component.button.Button("Reorder");
        com.vaadin.flow.component.html.OrderedList list = new com.vaadin.flow.component.html.OrderedList();
        Runnable renderList = () -> {
            list.removeAll();
            for (Row r : rows) {
                list.add(new com.vaadin.flow.component.html.ListItem(r.id() + " - " + r.label()));
            }
        };
        renderList.run();
        reorder.addClickListener(e -> {
            java.util.Collections.reverse(rows);
            renderList.run();
        });
        demo.add(list, reorder);
    }

    // ---- binary-payload: bytes in the body + digest ----
    static void binaryPayload(Div demo) {
        Upload upload = new Upload();
        upload.setMaxFileSize(8 * 1024 * 1024);
        com.vaadin.flow.component.html.Div report = new com.vaadin.flow.component.html.Div();
        upload.setUploadHandler(event -> {
            java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
            try (InputStream in = event.getInputStream()) {
                in.transferTo(out);
                byte[] bytes = out.toByteArray();
                byte[] digest = java.security.MessageDigest.getInstance("SHA-256").digest(bytes);
                StringBuilder hex = new StringBuilder();
                for (byte b : digest) {
                    hex.append(String.format("%02x", b));
                }
                push(demo, () -> report.add(
                        new com.vaadin.flow.component.html.Paragraph("bytes recebidos: " + bytes.length),
                        new com.vaadin.flow.component.html.Paragraph("sha256: " + hex)));
            } catch (Exception e) {
                push(demo, () -> report.add(new com.vaadin.flow.component.html.Paragraph("error: " + e.getMessage())));
            }
        });
        demo.add(upload, report);
    }

    // ---- todo-mvc: CRUD via @@post/@@patch/@@delete ----
    static void todoMvc(Div demo) {
        TextField input = new TextField("What needs to be done?");
        UnorderedList list = new UnorderedList();
        input.addKeyDownListener(Key.ENTER, e -> {
            if (!input.getValue().isBlank()) {
                list.add(new ListItem(input.getValue()));
                input.clear();
            }
        });
        demo.add(input, list);
    }
}

/**
 * Shared state of the multi-client-counter: an AtomicReference + registered UIs
 * (the "bus" of the Kotlin example, which uses EventBus/Elixir PubSub). Each
 * view
 * registers with subscribe; the broadcast runs ui.access on every registered
 * UI.
 */
final class MultiClientBus {

    private static final java.util.concurrent.atomic.AtomicInteger VALUE = new java.util.concurrent.atomic.AtomicInteger(
            0);
    private static final java.util.Set<java.util.function.IntConsumer> SUBSCRIBERS = java.util.Collections
            .synchronizedSet(new java.util.HashSet<>());
    private static final java.util.Set<com.vaadin.flow.component.UI> UIS = java.util.Collections
            .synchronizedSet(new java.util.HashSet<>());

    private MultiClientBus() {
    }

    static int value() {
        return VALUE.get();
    }

    static int increment() {
        return VALUE.incrementAndGet();
    }

    /**
     * Registers the current view as a subscriber; returns the initial value with a
     * push.
     */
    static void subscribe(java.util.function.IntConsumer onValue) {
        SUBSCRIBERS.add(onValue);
        com.vaadin.flow.component.UI ui = com.vaadin.flow.component.UI.getCurrent();
        if (ui != null) {
            UIS.add(ui);
            // initial value right at binding
            onValue.accept(VALUE.get());
        }
    }

    static void broadcast(int v) {
        // ui.access is mandatory when the change does not come from that UI's
        // request thread (in the Kotlin example the SSE bus; here, a request from
        // another
        // window). The UI registered in subscribe encapsulates the session lock -
        // ui.access on it runs the update in the right session, holding the lock.
        for (com.vaadin.flow.component.UI ui : UIS.toArray(new com.vaadin.flow.component.UI[0])) {
            ui.access((com.vaadin.flow.server.Command) () -> {
                for (java.util.function.IntConsumer s : SUBSCRIBERS.toArray(new java.util.function.IntConsumer[0])) {
                    s.accept(v);
                }
            });
        }
        // nota: cada consumer executa em todas as UIs - suficiente para o
        // didactic trace; the sender re-applies the local assign on click.
    }
}
