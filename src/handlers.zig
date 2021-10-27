const std = @import("std");
const network = @import("network");
const DNSPacket = @import("lib/dns_packet.zig").DNSPacket;
const dns_packet_size = @import("lib/packet_buffer.zig").dns_packet_size;
const DNSPacketBuffer = @import("lib/packet_buffer.zig").DNSPacketBuffer;
const DNSHeader = @import("lib/dns_header.zig").DNSHeader;
const DnsRecord = @import("lib/dns_record.zig").DnsRecord;
const DNSQuestion = @import("lib/dns_query.zig").DNSQuestion;
const Database = @import("database.zig").Database;
const NSRecord = @import("lib/dns_record.zig").NSRecord;

const processing_errors = error {
        INVALID_NUMBER
};

fn getPrefix(memory: *std.mem.Allocator, phone_number: []u8) ![]u8 {
    if (!std.mem.containsAtLeast(u8, phone_number,1, ".")) return processing_errors.INVALID_NUMBER;
    var buf = try memory.alloc(u8, 6);
    var suffix_started: bool = false;
    var suffix_count: usize = 0;

    for (phone_number) |v, i| {
        if (v == '.') suffix_started = true;
        if (suffix_count > 2) return buf[0..i];
        if (suffix_started) suffix_count += 1;

        buf[i] = phone_number[i];
    }

    return buf[0..];
}

pub fn processDNSRequest(memory: *std.mem.Allocator, request: *DNSPacket, db: *Database) ![]u8 {
    var res = DNSPacket{
        .header = request.header,
        .questions = std.ArrayList(DNSQuestion).init(memory),
        .answers = std.ArrayList(DnsRecord).init(memory),
        .authorities = std.ArrayList(DnsRecord).init(memory),
        .resources = std.ArrayList(DnsRecord).init(memory),
    };

    res.questions = request.questions;

    for (request.questions.items) |q| {
        const prefix =  getPrefix(memory, q.phone_number) catch "";
        const carrier = db.find(prefix) catch "";
        std.log.debug("for {s} the carierr is {s}", .{ prefix, carrier });

        res.header.response = true;
        if (carrier.len <= 0) {
            res.header.rescode = .NOTZONE;
        } else {
            res.header.rescode = .NOERROR;
            res.answers.append(DnsRecord{ .NS = NSRecord{ .phone_number = q.phone_number, .provider_name = carrier, .provider_code = carrier, .ttl = 300 } }) catch |err| {
                std.log.err("failed to build response {any}", .{err});
            };
        }
    }

    var buf = try memory.alloc(u8, 512);
    var pk_buffer = DNSPacketBuffer{ .buffer = buf[0..] };
    try res.write(&pk_buffer);
    return pk_buffer.toBuffer();
}
