const pl = @import("player.zig");
const rl = @import("raylib");

const std = @import("std");
const builtin = @import("builtin");

const Io = std.Io;
const io = Io.Threaded.global_single_threaded.io();

pub var shfps: bool = false;
const dbgKey: rl.KeyboardKey = rl.KeyboardKey.left_control;

pub fn check(player: *pl.Player) !void {
    if (shfps) {
        rl.drawFPS(0, 0);
    }

    // show fps
    if (rl.isKeyPressed(rl.KeyboardKey.f3)) {
        shfps = !shfps;
    }

    // show pos
    if (rl.isKeyDown(dbgKey) and rl.isKeyDown(rl.KeyboardKey.one)) {
        var allocator = std.heap.page_allocator;

        const pos: []u8 = try std.fmt.allocPrint(allocator, "{d}, {d}", .{ player.pos.x, player.pos.y });
        defer allocator.free(pos);

        const buf: [:0]u8 = try allocator.allocSentinel(u8, pos.len, 0);
        defer allocator.free(buf);
        @memcpy(buf, pos);

        rl.drawText(buf, 0, 0, 20, rl.Color.white);
    }

    // trigger exception
    if (builtin.mode == .Debug and rl.isKeyDown(dbgKey) and rl.isKeyPressed(rl.KeyboardKey.delete)) {
        return error.ManuallyTriggeredException;
    }
    if (builtin.mode == .Debug and rl.isKeyDown(dbgKey) and rl.isKeyPressed(rl.KeyboardKey.f4)) {
        return error.ManuallyTriggeredCrash;
    }
    if (builtin.mode == .Debug and rl.isKeyDown(dbgKey) and rl.isKeyPressed(rl.KeyboardKey.f5)) {
        return error.ManualForceFallThroughError;
    }
    if (builtin.mode == .Debug and rl.isKeyDown(dbgKey) and rl.isKeyPressed(rl.KeyboardKey.f6)) {
        return error.OutOfMemory;
    }
}
