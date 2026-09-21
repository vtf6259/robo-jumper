const std = @import("std");
const bSettings = @import("buildSettings.zig");

pub fn errorLogNonFatal(comptime format: []const u8, args: anytype, src: std.builtin.SourceLocation) void {
    std.log.warn("=== Non-fatal error ===", .{});
    std.log.warn(
        "You can continue playing, but please save and back up your save file as soon as possible.",
        .{},
    );
    std.log.err("Error details:", .{});
    std.log.err(format, args);
    std.log.err("{d}:{s}@{s}", .{ src.line, src.fn_name, src.file });
    std.log.warn("Please report this error at: {s}", .{bSettings.bugTrackerUrl});
}

pub fn errorLogFatal(comptime format: []const u8, args: anytype, src: std.builtin.SourceLocation) void {
    std.log.warn("=== A fatal error has occurred ===", .{});
    std.log.warn(
        "The game has crashed. Back up your save file as soon as possible.",
        .{},
    );
    std.log.warn("You should not continue playing until you have backed up your save.", .{});
    std.log.err("Error details:", .{});
    std.log.err(format, args);
    std.log.err("{d}:{s}@{s}", .{ src.line, src.fn_name, src.file });
    std.log.warn("Please report this error at: {s}", .{bSettings.bugTrackerUrl});
    std.debug.print("Here we are trying to show a notification if your terminal does not support it you may see weird characters if it does you will see nothing:\n\x1b]9;{s}: A fatal crash please see the log at: (TODO: Put it here (we do not have a save directory yet)).\x1b\\", .{bSettings.gameName});
    @panic("A fatal error has occurred see previous log output");
}
