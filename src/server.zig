const std = @import("std");
const network = @import("network");
const Socket = network.Socket;
const DNSPacket = @import("lib/dns_packet.zig").DNSPacket;
const dns_packet_size = @import("lib/packet_buffer.zig").dns_packet_size;
const DNSPacketBuffer = @import("lib/packet_buffer.zig").DNSPacketBuffer;
const DNSHeader = @import("lib/dns_header.zig").DNSHeader;
const DnsRecord = @import("lib/dns_record.zig").DnsRecord;
const DNSQuestion = @import("lib/dns_query.zig").DNSQuestion;
const e164_max_phone_number_len = @import("lib/packet_buffer.zig").e164_max_phone_number_len;
const Database = @import("database.zig").Database;
const functions = @import("handlers.zig");

pub const io_mode = .evented;

pub const IPv4 = network.Address.IPv4;

pub const packet_size = 100;

const Client = struct {
    peer: network.EndPoint,
    packet: [packet_size]u8,
    handle_frame: @Frame(handle),

    inline fn handle(this: *Client, conn: Server) !void {
        const allocator = std.heap.page_allocator;

        var pk_buffer_r = DNSPacketBuffer{ .buffer = this.packet[0..] };

        var pk = DNSPacket{
            .header = DNSHeader{},
            .questions = std.ArrayList(DNSQuestion).init(allocator),
            .answers = std.ArrayList(DnsRecord).init(allocator),
            .authorities = std.ArrayList(DnsRecord).init(allocator),
            .resources = std.ArrayList(DnsRecord).init(allocator),
        };
        try pk.fromBuffer(&pk_buffer_r);
        const res = try functions.processDNSRequest(allocator, &pk, conn.db);

        _ = conn.server.sendTo(this.peer, res) catch |err| {
            std.log.err("failed to send response to {}: {v}", .{ this.peer, err });
            @panic("");
        };
    }

    fn new() @This() {
        return Client{ .peer = undefined, .packet = undefined, .handle_frame = undefined };
    }
};

pub const Server = struct {
    db: *Database = undefined,
    server: Socket,
    options: struct { ip: IPv4, port: u16 },

    pub fn init(ip: []const u8, port: u16) !Server {
        if (ip.len < 7) return error.InvalidIP;
        try network.init();

        var srv = try network.Socket.create(.ipv4, .udp);
        try srv.enablePortReuse(true);

        var it = std.mem.split(u8, ip, ".");
        return Server{ .server = srv, .options = .{ .ip = IPv4.init(parseu8(it.next().?), parseu8(it.next().?), parseu8(it.next().?), parseu8(it.next().?)), .port = port } };
    }

    fn parseu8(buf: []const u8) u8 {
        return std.fmt.parseUnsigned(u8, buf, 0) catch unreachable;
    }

    pub fn startWithDB(this: *Server, db: *Database) !void {
        this.db = db;
        try this.start();
    }

    pub fn start(this: *Server) !void {
        var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = &general_purpose_allocator.allocator;
        try this.server.bind(.{ .address = .{ .ipv4 = this.options.ip }, .port = this.options.port });
        std.log.info("server listening on {}\n", .{this.server.getLocalEndPoint()});

        while (true) {
            const client = try allocator.create(Client);
            client.* = Client.new();
            const receive_from = try this.server.receiveFrom(&client.packet);
            client.peer = receive_from.sender;
            client.handle_frame = async client.handle(this.*);
        }
    }

    pub fn stop(this: *Server) void {
        defer network.deinit();
        defer this.server.close();
    }
};
