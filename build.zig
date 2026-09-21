const std = @import("std");
const Io = std.Io;

fn aseprite(
    asePath: []const u8,
    b: *std.Build,
    outPath: []const u8,
    allocator: std.mem.Allocator,
) *std.Build.Step.Run {
    const newPath = Io.Dir.path.join(
        allocator,
        &.{ outPath, "{frame}.png" },
    ) catch |err| {
        std.debug.panic(
            "failed to generate sprites for '{s}', outpath: {s}: {s}",
            .{
                asePath,
                outPath,
                @errorName(err),
            },
        );
    };

    return b.addSystemCommand(&.{
        "aseprite",
        "-b",
        asePath,
        "-scale",
        "4",
        "--save-as",
        newPath,
    });
}

fn createDirectory(io: Io, path: []const u8) void {
    Io.Dir.cwd().createDirPath(io, path) catch |err| {
        // createDirPath does not return PathAlreadyExists.
        std.debug.panic(
            "failed to create '{s}': {s}",
            .{
                path,
                @errorName(err),
            },
        );
    };
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug,
    });

    // Distribution builds use ReleaseSafe.
    const dist_optimize: std.builtin.OptimizeMode = .ReleaseSafe;

    // ------------------------------------------------------------
    // Dependencies
    // ------------------------------------------------------------

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // ------------------------------------------------------------
    // Main module
    // ------------------------------------------------------------

    const mod = b.addModule("2d_platformer", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ------------------------------------------------------------
    // Sprite generation
    // ------------------------------------------------------------

    createDirectory(
        Io.Threaded.global_single_threaded.io(),
        "assets/autogen/playerAnim",
    );

    const playerAnim = aseprite(
        "player.aseprite",
        b,
        "assets/autogen/playerAnim",
        b.allocator,
    );

    const export_step = b.step(
        "sprites",
        "Exports all of the sprites",
    );

    export_step.dependOn(&playerAnim.step);

    // ------------------------------------------------------------
    // Normal executable
    // ------------------------------------------------------------

    const exe = b.addExecutable(.{
        .name = "2d_platformer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,

            .imports = &.{
                .{
                    .name = "2d_platformer",
                    .module = mod,
                },
            },
        }),
    });

    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    exe.step.dependOn(export_step);

    b.installArtifact(exe);

    // ------------------------------------------------------------
    // Run
    // ------------------------------------------------------------

    const run_step = b.step(
        "run",
        "Run the app",
    );

    const run_cmd = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ------------------------------------------------------------
    // Tests
    // ------------------------------------------------------------

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step(
        "test",
        "Run tests",
    );

    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // ------------------------------------------------------------
    // Distribution executable
    // ------------------------------------------------------------

    const dist_exe = b.addExecutable(.{
        .name = "2d_platformer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = dist_optimize,

            .imports = &.{
                .{
                    .name = "2d_platformer",
                    .module = mod,
                },
            },
        }),
    });

    dist_exe.root_module.linkLibrary(raylib_artifact);
    dist_exe.root_module.addImport("raylib", raylib);

    dist_exe.step.dependOn(export_step);

    // ------------------------------------------------------------
    // Distribution
    // ------------------------------------------------------------

    createDirectory(
        Io.Threaded.global_single_threaded.io(),
        "dist",
    );

    const dist_step = b.step(
        "dist",
        "Build and package the game",
    );

    const target_os = target.result.os.tag;

    if (target_os == .windows) {
        const archive = b.addSystemCommand(&.{
            "tar",
            "-a",
            "-c",
            "-f",
            "dist/2d_platformer.zip",
            "-C",
            "zig-out/bin",
            "2d_platformer.exe",
            "-C",
            "../../",
            "assets",
        });

        archive.step.dependOn(&dist_exe.step);

        dist_step.dependOn(&archive.step);
    } else {
        const archive = b.addSystemCommand(&.{
            "tar",
            "-a",
            "-c",
            "-f",
            "dist/2d_platformer.zip",
            "-C",
            "zig-out/bin",
            "2d_platformer",
            "-C",
            "../../",
            "assets",
        });

        archive.step.dependOn(&dist_exe.step);

        dist_step.dependOn(&archive.step);
    }
}
