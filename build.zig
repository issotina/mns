const std = @import("std");

const pkgs = struct {
    const network = std.build.Pkg{
        .name = "network",
        .path = .{ .path = "deps/network/network.zig" },
    };
    const lmdb = std.build.Pkg{
        .name = "lmdb",
        .path = .{ .path = "deps/lmdb/lmdb.zig" },
    };
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("mns", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.addIncludeDir("deps/liblmdb/libraries/liblmdb");
    exe.addCSourceFiles(&[2][]const u8{ "deps/liblmdb/libraries/liblmdb/mdb.c", "deps/liblmdb/libraries/liblmdb/midl.c" }, &[1][]const u8{
        "-fno-sanitize=undefined",
    });
    exe.addPackage(pkgs.network);
    exe.addPackage(pkgs.lmdb);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    var exe_tests = b.addTest("src/main.zig");
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
