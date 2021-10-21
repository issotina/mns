
const std = @import("std");
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError = @import("packet_buffer.zig").ReadPacketError;
const e164_max_phone_number_len = @import("packet_buffer.zig").e164_max_phone_number_len;
pub const QueryType  = enum(u16) {
    P, // To query wallet provider
    UNKNOW,

    pub fn from(num: u16) QueryType{
       return switch (num) {
             1 => QueryType.P,
            else => QueryType.UNKNOW,
        };
    }
};

pub const QueryClass  = enum(u16) {
   DEFAULT,

    pub fn from(_: u16) QueryClass{
        //TODO: Add support for classes
       return QueryClass.DEFAULT;
    }
};

pub const DNSQuestion = struct {
    phone_number: std.ArrayList(u8) = undefined,
    query_type: QueryType = QueryType.UNKNOW,
    query_class: QueryClass = QueryClass.DEFAULT,

     pub fn read( this: *DNSQuestion, buffer: *DNSPacketBuffer) anyerror!void {
   
    this.phone_number = std.ArrayList(u8).init(std.heap.page_allocator);
    
    try buffer.readPhoneNumber(&this.phone_number);
    this.query_type = QueryType.from(try buffer.readU16()); 
    this.query_class = QueryClass.from(try buffer.readU16());
    }
};