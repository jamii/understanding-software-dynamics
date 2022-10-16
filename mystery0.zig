const std = @import("std");
const util = @import("util.zig");

const k_iterations = 1_000 * 1_000_000;

pub fn main() void {
    var sum: u64 = 0;
    const start = util.rdtscp();
    var i: usize = 0;
    while (i < k_iterations) : (i += 1) {
        sum += 1;
    }
    const elapsed = util.rdtscp() - start;
    std.debug.print("{} iterations, {} cycles, {d:0>6.2} cycles/iteration", .{
        k_iterations,
        elapsed,
        @intToFloat(f64, elapsed) / @intToFloat(f64, k_iterations),
    });
}
