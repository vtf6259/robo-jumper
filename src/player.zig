const rl = @import("raylib");
const debug = @import("debug.zig");
const std = @import("std");
const utils = @import("utils.zig");

pub const Player = struct {
    texture: rl.Texture,
    textures: []rl.Texture,
    currentTextureFrame: usize = 0,
    animationTimer: f32 = 0.0,
    animationSpeed: f32 = 0.1,
    pos: rl.Vector2,
    size: rl.Vector2,
    boundry: rl.Vector2,
};

pub fn updatePlayer(player: *Player) !void {
    player.animationTimer += rl.getFrameTime();

    if (player.animationTimer >= player.animationSpeed) {
        player.animationTimer -= player.animationSpeed;

        player.currentTextureFrame = (player.currentTextureFrame + 1) % player.textures.len;

        player.texture = player.textures[player.currentTextureFrame];
    }
    rl.drawTextureV(player.texture, player.pos, rl.Color.white);
    debug.check(player) catch |err| switch (err) {
        error.ManuallyTriggeredCrash => {
            utils.errorLogFatal("error in debug.check {s}", .{@errorName(err)}, @src());
        },
        error.ManualForceFallThroughError => {
            return err;
        },
        error.OutOfMemory => {
            utils.errorLogFatal("We have ran out of memory in debug.check: {s}", .{@errorName(err)}, @src());
        },
        else => { // not something to crash for if this fails
            utils.errorLogNonFatal("error in debug.check {s}", .{@errorName(err)}, @src());
        },
    };
}
