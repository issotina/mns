const std = @import("std");
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const allocator = std.heap.page_allocator;
const QueryType = @import("dns_query.zig").QueryType;
const QueryClass = @import("dns_query.zig").QueryClass;

pub const PRecord = struct {
};

pub const PNRecord = struct {};
pub const PCRecord = struct {};
pub const NSRecord = struct {
     phone_number: []const u8,
    provider_name: []const u8,
    provider_code: []const u8,
    ttl: u32,
};

pub const DnsRecord = union(QueryType) {
    P: PRecord,
    PN: PNRecord,
    PC: PCRecord,
    NS: NSRecord,
    UNKNOW: u8,



    pub fn write(this: DnsRecord, packet_buffer: *DNSPacketBuffer) !void {
        switch (this) {
             .NS => {
                try packet_buffer.writeQName(this.NS.phone_number);
                try packet_buffer.writeU16(@enumToInt(QueryType.NS));
                try packet_buffer.writeU16(@enumToInt(QueryClass.DEFAULT));
                try packet_buffer.writeU32(this.NS.ttl);

                const pos = packet_buffer.pos();
                try packet_buffer.writeU16(0);

                try packet_buffer.writeQName(this.NS.provider_code);

                const size = packet_buffer.pos() - (pos + 2);
                try packet_buffer.setU16(pos, @truncate(u16, size));
            },
            else =>  try packet_buffer.writeU16(0)
        }
    }
};
