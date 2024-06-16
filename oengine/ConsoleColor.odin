package oengine

import "core:fmt"

// ansi colors

ConsoleColor :: proc(string) -> string

@(private = "file")
ESC :: "\033["

C_RESET              :: ESC + "0m"
C_BLACK              :: ESC + "30m"
C_RED                :: ESC + "31m"
C_GREEN              :: ESC + "32m"
C_YELLOW             :: ESC + "33m"
C_BLUE               :: ESC + "34m"
C_MAGENTA            :: ESC + "35m"
C_CYAN               :: ESC + "36m"
C_WHITE              :: ESC + "37m"

C_ON_BLACK           :: ESC + "40m"
C_ON_RED             :: ESC + "41m"
C_ON_GREEN           :: ESC + "42m"
C_ON_YELLOW          :: ESC + "43m"
C_ON_BLUE            :: ESC + "44m"
C_ON_MAGENTA         :: ESC + "45m"
C_ON_CYAN            :: ESC + "46m"
C_ON_WHITE           :: ESC + "47m"

C_BRIGHT_BLACK       :: ESC + "90m"
C_BRIGHT_RED         :: ESC + "91m"
C_BRIGHT_GREEN       :: ESC + "92m"
C_BRIGHT_YELLOW      :: ESC + "93m"
C_BRIGHT_BLUE        :: ESC + "94m"
C_BRIGHT_MAGENTA     :: ESC + "95m"
C_BRIGHT_CYAN        :: ESC + "96m"
C_BRIGHT_WHITE       :: ESC + "97m"

C_ON_BRIGHT_BLACK    :: ESC + "100m"
C_ON_BRIGHT_RED      :: ESC + "101m"
C_ON_BRIGHT_GREEN    :: ESC + "102m"
C_ON_BRIGHT_YELLOW   :: ESC + "103m"
C_ON_BRIGHT_BLUE     :: ESC + "104m"
C_ON_BRIGHT_MAGENTA  :: ESC + "105m"
C_ON_BRIGHT_CYAN     :: ESC + "106m"
C_ON_BRIGHT_WHITE    :: ESC + "107m"

@(private = "file")
color :: proc(color, input: string) -> string {
    return fmt.aprintf("%s%s%s", color, input, C_RESET)
}

black :: proc(input: string) -> string {
    return color(C_BLACK, input)
}

red :: proc(input: string) -> string {
    return color(C_RED, input)
}

green :: proc(input: string) -> string {
    return color(C_GREEN, input)
}

yellow :: proc(input: string) -> string {
    return color(C_YELLOW, input)
}

blue :: proc(input: string) -> string {
    return color(C_BLUE, input)
}

magenta :: proc(input: string) -> string {
    return color(C_MAGENTA, input)
}

cyan :: proc(input: string) -> string {
    return color(C_CYAN, input)
}

white :: proc(input: string) -> string {
    return color(C_WHITE, input)
}

on_white :: proc(input: string) -> string {
    return color(C_ON_WHITE, input)
}

on_black :: proc(input: string) -> string {
    return color(C_ON_BLACK, input)
}

on_red :: proc(input: string) -> string {
    return color(C_ON_RED, input)
}

on_green :: proc(input: string) -> string {
    return color(C_ON_GREEN, input)
}

on_yellow :: proc(input: string) -> string {
    return color(C_ON_YELLOW, input)
}

on_blue :: proc(input: string) -> string {
    return color(C_ON_BLUE, input)
}

on_magenta :: proc(input: string) -> string {
    return color(C_ON_MAGENTA, input)
}

on_cyan :: proc(input: string) -> string {
    return color(C_ON_CYAN, input)
}

bright_white :: proc(input: string) -> string {
    return color(C_BRIGHT_WHITE, input)
}

bright_black :: proc(input: string) -> string {
    return color(C_BRIGHT_BLACK, input)
}

bright_red :: proc(input: string) -> string {
    return color(C_BRIGHT_RED, input)
}

bright_green :: proc(input: string) -> string {
    return color(C_BRIGHT_GREEN, input)
}

bright_yellow :: proc(input: string) -> string {
    return color(C_BRIGHT_YELLOW, input)
}

bright_blue :: proc(input: string) -> string {
    return color(C_BRIGHT_BLUE, input)
}

bright_magenta :: proc(input: string) -> string {
    return color(C_BRIGHT_MAGENTA, input)
}

bright_cyan :: proc(input: string) -> string {
    return color(C_BRIGHT_CYAN, input)
}

on_bright_black :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_BLACK, input)
}

on_bright_red :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_RED, input)
}

on_bright_green :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_GREEN, input)
}

on_bright_yellow :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_YELLOW, input)
}

on_bright_blue :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_BLUE, input)
}

on_bright_magenta :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_MAGENTA, input)
}

on_bright_cyan :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_CYAN, input)
}

on_bright_white :: proc(input: string) -> string {
    return color(C_ON_BRIGHT_WHITE, input)
}
