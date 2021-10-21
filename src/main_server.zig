const std = @import("std");
const Server = @import("server.zig").Server;
const IPv4 = @import("server.zig").IPv4;
const clap = @import("clap");

pub fn main() !void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --help             Display this help and exit.              ") catch unreachable,
        clap.parseParam("-p, --port <NUM>     listening server port.") catch unreachable,
    };

    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer args.deinit();

    std.log.info("port set is : {}", args.flag("--port"));
    var server = try Server.init(IPv4.init(127, 0, 0, 1), 9090);

    server.start() catch |err| {
        std.log.err("failed to start server: {}", .{err});
    };
}
