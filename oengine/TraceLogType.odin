package oengine

TRACE_NAMES := [3]string {
    "RAYLIB",
    "OENGINE",
    "BOTH",
}

TraceLogType :: enum {
    USE_RAYLIB,
    USE_OENGINE,
    USE_ALL,
}