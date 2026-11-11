"""
Count wiring points per example in the HtmlFlow-Datastar corparison.

A wiring point is one piece of handwritten code that joins an interaction to its effect.
The count is made mechanically, from the view file, against an explicit list of markers,
so that the number in the report can be reproduced and audited rather than trusted.

Markers, by category:
  route     - a backend action naming the endpoint it calls:  get( post( put( patch( delete(
  stream    - an attribute that opens or names a stream:      dataInit, dataOn, dataOnIntersect,
                                                              dataOnInterval, dataOnSignalPatch
  binding   - a two-way binding to a client value:            dataBind, dataSignal, dataSignals,
                                                              dataComputed
  indicator - a progress/dirty marker:                        dataIndicator, dataAttr, dataEffect
  reading   - a read of a signal inside an expression:        signal.on(, +signal, +fetching, etc.
  semantic  - the decisions that stay with the programmer:    event names in dataOn(...),
                                                              HTTP method chosen, target attrId,
                                                              logic passed as +string

Usage:  python count-wiring-points.py <dir-with-views>
"""

import re
import sys
from pathlib import Path

# A route call: get( post( put( patch( delete( at a call position.
ROUTE = re.compile(r"\b(get|post|put|patch|delete)\s*[({]")
STREAM = re.compile(
    r"\b(dataInit|dataOn|dataOnIntersect|dataOnInterval|dataOnSignalPatch)\b"
)
BINDING = re.compile(r"\b(dataBind|dataSignal|dataSignals|dataComputed)\b")
INDICATOR = re.compile(r"\b(dataIndicator|dataAttr|dataEffect)\b")
# A read of a signal: the unary plus applied to an identifier or a call.
READING = re.compile(r"\+\s*(?:[A-Za-z_][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*\s*\()")
# The decisions that remain semantic: an event in an on-handler, a target id, a method.
EVENT = re.compile(
    r"\bdata(?:On|OnIntersect|OnInterval|OnSignalPatch)\s*\(\s*([A-Z][A-Za-z0-9]*)"
)
TARGET = re.compile(r"\battrId\s*\(")
# A decision taken as raw text rather than through a builder.
RAW = re.compile(r"\+\$\$?\"")


def count(path):
    text = path.read_text(encoding="utf-8")
    # Comments describe the example; they are not wiring.
    lines = [ln for ln in text.splitlines() if not ln.lstrip().startswith("//")]
    body = "\n".join(lines)
    return {
        "routes": len(ROUTE.findall(body)),
        "streams": len(STREAM.findall(body)),
        "bindings": len(BINDING.findall(body)),
        "indicators": len(INDICATOR.findall(body)),
        "readings": len(READING.findall(body)),
        "events": len(EVENT.findall(body)),
        "targets": len(TARGET.findall(body)),
        "raw": len(RAW.findall(body)),
    }


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    files = sorted(root.glob("*.kt"))
    if not files:
        print("no .kt files under", root, file=sys.stderr)
        return 1

    header = ("example", "route", "stream", "bind", "ind", "read", "semantic", "total")
    print("| " + " | ".join(header) + " |")
    print("|" + "|".join(["---"] * len(header)) + "|")
    for f in files:
        c = count(f)
        mechanical = (
            c["routes"] + c["streams"] + c["bindings"] + c["indicators"] + c["readings"]
        )
        semantic = c["events"] + c["targets"] + c["raw"]
        print(
            "| %s | %d | %d | %d | %d | %d | %d | %d |"
            % (
                f.stem,
                c["routes"],
                c["streams"],
                c["bindings"],
                c["indicators"],
                c["readings"],
                semantic,
                mechanical + semantic,
            )
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
