package org.vaadin.example;

import com.vaadin.flow.component.dependency.StyleSheet;
import com.vaadin.flow.component.page.AppShellConfigurator;
import com.vaadin.flow.component.page.Push;
import com.vaadin.flow.server.PWA;
import com.vaadin.flow.shared.communication.PushMode;
import com.vaadin.flow.shared.ui.Transport;
import com.vaadin.flow.theme.lumo.Lumo;

/**
 * Global app configuration.
 *
 * AUTOMATIC push is the analogue of BRHC's data-init @@get: without @Push,
 * ui.access() only delivers changes on the client's next request and the
 * exemplos server-driven (progress-bar, lazy-load, progressive-load) ficam
 * congelados.
 */
@Push(value = PushMode.AUTOMATIC, transport = Transport.WEBSOCKET_XHR)
@PWA(name = "BRHC Vaadin Trace", shortName = "BRHC 18")
@StyleSheet(Lumo.STYLESHEET)
@StyleSheet("styles.css")
public class AppShell implements AppShellConfigurator {
}
