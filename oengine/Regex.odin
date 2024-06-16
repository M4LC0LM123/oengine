package oengine

import "core:fmt"

oe_match :: proc(buf, frmt: string) -> [dynamic]string {
    res: [dynamic]string;

    for i in 0..<len(frmt) - 1 {
        if (frmt[i] == '%' && frmt[i + 1] == 'v') {
            end: int;
            for j in i..<len(buf) {
                if (buf[j] == frmt[i + 2]) {
                    end = j;
                    break;
                }
            }

            fmt.printf("%v, %v, ", i, end);
            fmt.printf("val: %v\n", buf[i:end]);
            append(&res, buf[i:end]);
        }
    }

    return res;
}
