const std = @import("std");
const Database = @import("database.zig").Database;
const Server = @import("server.zig").Server;
const IPv4 = @import("server.zig").IPv4;
const clap = @import("clap");
const config = @import("config.zig");

pub fn main() anyerror!void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --help             Display this help and exit.              ") catch unreachable,
        clap.parseParam("-v, --verbosity <NUM>  the log level in increasing order of verbosity(1..7)") catch unreachable,
        clap.parseParam("-i, --address <STR> the default network interface address to listen on") catch unreachable,
        clap.parseParam("-p, --port <NUM>    default port for dns server") catch unreachable,
        clap.parseParam("-d, --dir <STR>    where data files should be persisted") catch unreachable,
    };
    const allocator = std.heap.page_allocator;
    
    var iter = try clap.args.OsIterator.init(allocator);
    defer iter.deinit();
    var diag = clap.Diagnostic{};
    var args = clap.parseEx(clap.Help, &params, &iter, .{
        .allocator = allocator,
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer args.deinit();

    if (args.option("--dir") == null) {
        std.log.err("missing argument --dir",.{});
        try clap.help(std.io.getStdErr().writer(),&params);
        std.os.exit(1);
    }

    var db = try Database.open(try std.fs.path.join(allocator, &[2][]const u8{ args.option("--dir") orelse config._data_dir, ".db" }));
    const port = try std.fmt.parseUnsigned(u16, (args.option("--port") orelse config._port), 0);
    var server = try Server.init(args.option("--address") orelse config._address, port);

    server.startWithDB(&db) catch |err| {
        std.log.err("failed to start server: {}", .{err});
    };
}
