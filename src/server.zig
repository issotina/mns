const std = @import("std");
const network = @import("network");
const Socket = network.Socket;

pub const io_mode = .evented;

pub const IPv4 = network.Address.IPv4;

const Client = struct {
    conn:  Socket,
    handle_frame: @Frame(handle),

    fn handle(_: *Client) !void {
       // _ = try self.conn.stream.write("server: welcome to teh chat server\n");
        // while (true) {
        //     var buf: [100]u8 = undefined;
        //     const amt = try self.conn.stream.read(&buf);
        //     const msg = buf[0..amt];
        //     room.broadcast(msg, self);
        // }
    }
};

pub const Server = struct {
    server: Socket,
    options: struct { ip: IPv4, port: u16 },

    pub fn init( ip: IPv4, port: u16 ) !Server {
                try network.init();

        var srv = try network.Socket.create(.ipv4, .udp);
        return Server{ .server = srv, .options = .{.ip = ip, .port = port} };
    }

    pub fn start(this: *Server) !void {
        var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = &general_purpose_allocator.allocator;
        try this.server.bind(.{ .address = .{ .ipv4 = this.options.ip }, .port = this.options.port });
        try this.server.listen();
        std.log.info("server listening on {}\n", .{this.server.getLocalEndPoint()});

        while (true) {
            const client = try allocator.create(Client);
            client.* = Client{
                .conn = try this.server.accept(),
                .handle_frame = async client.handle(),
            };
        }
    }

    pub fn stop(this: *Server) void {
        defer network.deinit();
        defer this.server.close();
    }
};
