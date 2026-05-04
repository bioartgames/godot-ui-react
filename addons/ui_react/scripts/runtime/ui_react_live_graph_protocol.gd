## Wire identifiers for **`EngineDebugger`** (`CB-018` live graph). Shared by **`UiReactLiveGraphTransport`** and **`EditorDebuggerPlugin`** ingest.
extends RefCounted
class_name UiReactLiveGraphProtocol

const CAPTURE_PREFIX := "ui_react_graph"
const MSG_V1_WIRE := "ui_react_graph:v1_wire"
const MSG_V1_CMP := "ui_react_graph:v1_cmp"
const MSG_V1_ACT := "ui_react_graph:v1_act"
