const std = @import("std");
const Database = @import("database.zig").Database;
const Server = @import("server.zig").Server;
const IPv4 = @import("server.zig").IPv4;

pub fn main() anyerror!void {
    var db = try Database.open("/Users/shadai/Envirronement/mns/.db");
    
   // try db.loadFile("/Users/shadai/Envirronement/mns/deps/initial-data");
   var server = try Server.init(IPv4.init(127, 0, 0, 1), 5000);

   // TODO: Graceful shutdown and memory release 
    server.startWithDB(&db) catch |err| {
        std.log.err("failed to start server: {}", .{err});
    };
}
