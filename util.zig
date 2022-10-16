const std = @import("std");

fn rdtscp() u64 {
    var hi: u64 = undefined;
    var low: u64 = undefined;
    asm volatile (
        \\rdtscp
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
        :
        : "ecx"
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub fn main() void {
    const now = rdtscp();
    const later = rdtscp();
    std.debug.print("{}", .{later - now});
}
