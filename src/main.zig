const rl = @import("raylib");
const pl = @import("player.zig");
const std = @import("std");
const utils = @import("utils.zig");
const bSettings = @import("buildSettings.zig");
const Io = std.Io;
const io = Io.Threaded.global_single_threaded.io();

pub fn main() void {
    runGame() catch |err| {
        utils.errorLogFatal("An error has fallen through to main: {s}", .{@errorName(err)}, @src());
    };
}

fn runGame() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    rl.initWindow(800, 600, bSettings.gameName);
    rl.setTargetFPS(120);
    defer rl.closeWindow();

    const playerTextureDir = try Io.Dir.openDir(.cwd(), io, "assets/autogen/playerAnim", .{ .iterate = true });
    var walk = try playerTextureDir.walk(allocator);
    var playerTexturePaths: std.ArrayList([:0]const u8) = .empty;
    defer playerTexturePaths.deinit(allocator);

    var playerTextures: std.ArrayList(rl.Texture) = .empty;
    while (try walk.next(io)) |entry| {
        const relPath = try Io.Dir.path.joinZ(allocator, &.{ "assets", "autogen", "playerAnim", entry.path });
        try playerTexturePaths.append(allocator, relPath);
    }
    std.mem.sort(
        [:0]const u8,
        playerTexturePaths.items,
        {},
        struct {
            fn lessThan(_: void, a: [:0]const u8, b: [:0]const u8) bool {
                const a_num = std.fmt.parseInt(
                    u32,
                    std.fs.path.stem(a),
                    10,
                ) catch 0;

                const b_num = std.fmt.parseInt(
                    u32,
                    std.fs.path.stem(b),
                    10,
                ) catch 0;

                return a_num < b_num;
            }
        }.lessThan,
    );
    for (playerTexturePaths.items) |texturePath| {
        const texture = try rl.loadTexture(texturePath);
        try playerTextures.append(allocator, texture);
    }
    defer {
        for (playerTextures.items) |texture| {
            rl.unloadTexture(texture);
        }
    }

    var player: pl.Player = pl.Player{
        .texture = playerTextures.items[0],
        .textures = playerTextures.items,
        .pos = rl.Vector2{ .x = 0, .y = 0 },
        .size = rl.Vector2{ .x = 32, .y = 32 },
        .boundry = rl.Vector2{ .x = 0, .y = -1 },
    };
    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.black);
        rl.beginDrawing();
        try pl.updatePlayer(&player);
        rl.endDrawing();
    }
}
