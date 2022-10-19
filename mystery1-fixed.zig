const std = @import("std");
const util = @import("util.zig");

const total_count = 1 << 10;
const unroll_count = 1 << 6;
const loop_count_max = @divExact(total_count, unroll_count);

pub fn run(comptime op: anytype) void {
    var total = switch (op) {
        .add, .mul, .imul => @as(u32, 3),
        .div, .idiv => @as(u32, std.math.maxInt(u32)),
        .fmul => @as(f32, 3),
        .fdiv => @intToFloat(f32, std.math.maxInt(u23)),
        else => unreachable,
    };

    const incr = switch (op) {
        .add, .mul, .imul, .div, .idiv => @as(u32, 3),
        .fmul, .fdiv => @as(f32, 1.01),
        else => unreachable,
    };

    const start = util.rdtscp();

    var loop_index: usize = 0;
    while (loop_index < loop_count_max) : (loop_index += 1) {
        switch (op) {
            .add => asm volatile (
                \\add %%ebx, %%eax;
                ** unroll_count
                : [total] "={eax}" (total),
                : [total] "{eax}" (total),
                  [incr] "{ebx}" (incr),
            ),
            .mul => asm volatile (
                \\mul %%ebx;
                ** unroll_count
                : [total] "={eax}" (total),
                : [total] "{eax}" (total),
                  [incr] "{ebx}" (incr),
                : "edx"
            ),
            .imul => asm volatile (
                \\imul %%ebx, %%eax;
                ** unroll_count
                : [total] "={eax}" (total),
                : [total] "{eax}" (total),
                  [incr] "{ebx}" (incr),
            ),
            .div => asm volatile (
                \\xor %%edx, %%edx;
                \\div %%ebx;
                ** unroll_count
                : [total] "={eax}" (total),
                : [total] "{eax}" (total),
                  [incr] "{ebx}" (incr),
                : "edx"
            ),
            .idiv => asm volatile (
                \\xor %%edx, %%edx;
                \\idiv %%ebx;
                ** unroll_count
                : [total] "={eax}" (total),
                : [total] "{eax}" (total),
                  [incr] "{ebx}" (incr),
                : "edx"
            ),
            .fmul => asm volatile (
                \\fmul %%st(1), %%st(0);
                ** unroll_count
                : [total] "={st(0)}" (total),
                : [total] "{st(0)}" (total),
                  [incr] "{st(1)}" (incr),
            ),
            .fdiv => asm volatile (
                \\fdiv %%st(1), %%st(0);
                ** unroll_count
                : [total] "={st(0)}" (total),
                : [total] "{st(0)}" (total),
                  [incr] "{st(1)}" (incr),
            ),
            else => unreachable,
        }
    }

    const elapsed = util.rdtscp() - start;

    std.debug.print("{:>4} \t {d:>6.0} cycles \t {d:>6.2} cycles/iteration \t total={}\n", .{
        op,
        elapsed,
        @intToFloat(f64, elapsed) / loop_count_max / unroll_count,
        total,
    });
}

pub fn main() void {
    std.debug.print("{}x unrolled, {} iterations\n", .{
        unroll_count,
        loop_count_max,
    });

    inline for (.{
        .add,
        .mul,
        .imul,
        .div,
        .idiv,
        .fmul,
        .fdiv,
    }) |op| run(op);
}
