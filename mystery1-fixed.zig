const std = @import("std");
const util = @import("util.zig");

const k_iterations = 1_000 * 1_000_000;

pub fn main() void {
    var sum: u32 = 0;

    const time = std.time.timestamp();
    const incr = @intCast(u32, time & 255);

    const start = util.rdtscp();
    var i: usize = 0;
    while (i < k_iterations) : (i += 1) {
        asm volatile ("add %%ebx, %%eax"
            : [sum] "={eax}" (sum),
            : [sum] "{eax}" (sum),
              [incr] "{ebx}" (incr),
        );
    }
    const elapsed = util.rdtscp() - start;

    std.debug.print("{} sum, {} iterations, {} cycles, {d:0>6.2} cycles/iteration", .{
        sum,
        k_iterations,
        elapsed,
        @intToFloat(f64, elapsed) / @intToFloat(f64, k_iterations),
    });
}
