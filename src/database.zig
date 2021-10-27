const lmdb = @import("lmdb");
const Environment = lmdb.Environment;
const Transaction = lmdb.Transaction;
const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const allocator = std.heap.page_allocator;

pub const Database = struct {
    env: Environment,
    tx: Transaction,

    pub fn open(path: []const u8) anyerror!Database {
        const env = try Environment.init(path, .{ .use_writable_memory_map = true });
        const tx = try env.begin(.{});
        errdefer tx.deinit();
        return Database{ .env = env, .tx = tx };
    }

    pub fn insert(this: *Database, key: []const u8, val: []const u8) !void {
        const db = try this.tx.open(.{});
        defer db.close(this.env);
        try this.tx.put(db, key, val, .{ .dont_overwrite_key = true });
        try this.tx.commit();
    }

    pub inline fn find(this: *Database, key: []const u8) ![]const u8 {
        const db = try this.tx.open(.{});
        const v = try this.tx.get(db, key);
        //defer db.close(this.env);
        return v;
    }

    pub fn loadFile(this: *Database, dir_path: []const u8) !void {
        const db = try this.tx.open(.{});
        defer db.close(this.env);

        std.log.info("loading files from: {s} in database ...", .{dir_path});
        const max_line_size = 40;
        const delimiter = '\n';

        const dir = try fs.openDirAbsolute(dir_path, .{ .iterate = true });
        var walker = try dir.walk(std.heap.page_allocator);
        defer walker.deinit();
        while (try walker.next()) |fd| {
            if (std.mem.endsWith(u8, fd.basename, ".txt")) {
                std.log.debug("-> reading file: `{s}`", .{fd.path});

                var file = try fs.openFileAbsolute(try std.fs.path.join(allocator, &[2][]const u8{ dir_path, fd.path }), .{ .read = true });
                defer file.close();

                try file.seekTo(0);
                var buf: [max_line_size]u8 = undefined;
                var index: usize = 0;
                var key: []u8 = undefined;

                while (try file.reader().readUntilDelimiterOrEof(&buf, delimiter)) |line| {
                    defer index += 1;
                    if (builtin.os.tag == .windows) {
                        line = std.mem.trimRight(u8, line, "\r");
                    }
                    std.log.debug(">reading line {d}:`{s}` from {s}", .{ index, line, fd.path });
                    var it = std.mem.split(u8, line, ",");
                    if (it.next()) |k| {
                        key = try std.mem.concat(allocator, u8, &[2][]const u8{ std.mem.split(u8, fd.basename, "txt").next().?, k });
                        if (it.next()) |v| {
                            std.log.debug(">> insert({s},{s}) into database...", .{ key, v });
                            this.tx.put(db, key, v, .{ .dont_overwrite_key = true }) catch |err| {
                                if (err == error.AlreadyExists) {
                                    std.log.debug(">> skip insert({s},{s}). item already exist in databse...", .{ key, v });
                                } else return err;
                            };
                        }
                    }
                }
            }
        }
        try this.tx.commit();
    }

    pub fn close(this: *Database) void {
        this.tx.deinit();
        // this.env.deinit();
    }
};
