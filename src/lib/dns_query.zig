const std = @import("std");
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError = @import("packet_buffer.zig").ReadPacketError;
const e164_max_phone_number_len = @import("packet_buffer.zig").e164_max_phone_number_len;

pub const QueryType = enum(u16) {
    P = 1, 
    PN = 10,
    PC = 12,
    NS = 2,
    UNKNOW,

    pub fn from(num: u16) QueryType {
        return switch (num) {
            1 => QueryType.P,
            2 => QueryType.NS,
            else => QueryType.UNKNOW,
        };
    }
};

pub const QueryClass = enum(u16) {
    DEFAULT = 1,

    pub fn from(_: u16) QueryClass {
        //TODO: Add support for classes
        return QueryClass.DEFAULT;
    }
};

pub const DNSQuestion = struct {
    phone_number: []u8,
    query_type: QueryType = QueryType.NS,
    query_class: QueryClass = QueryClass.DEFAULT,

    pub fn read(this: *DNSQuestion, buffer: *DNSPacketBuffer) anyerror!void {
        try buffer.readQName(&this.phone_number);
        this.query_type = QueryType.from(try buffer.readU16());
        this.query_class = QueryClass.from(try buffer.readU16());
    }

    pub fn write(this: DNSQuestion, buffer: *DNSPacketBuffer) anyerror!void {
        try buffer.writeQName(this.phone_number);
        try buffer.writeU16(@enumToInt(this.query_type));
        try buffer.writeU16(@enumToInt(this.query_class));
    }
};
