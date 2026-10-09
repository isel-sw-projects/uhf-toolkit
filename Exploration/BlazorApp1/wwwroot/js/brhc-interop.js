// Interop JS mínimo para os exemplos BRHC em Blazor.
// No BRHC estes comportamentos são atributos Datastar declarativos
// (p.ex. data-on-intersect); aqui precisam de JS explícito - uma das
// diferenças que o UHF procura eliminar.
window.brhcInterop = {
  // Observa o sentinela do infinite-scroll e invoca o método .NET quando visível.
  observeSentinel: function (element, dotNetRef) {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            dotNetRef.invokeMethodAsync("OnSentinelVisible");
          }
        }
      },
      { rootMargin: "100px" },
    );
    observer.observe(element);
  },
};
