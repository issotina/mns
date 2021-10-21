const std = @import("std");
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const allocator = std.heap.page_allocator;

pub const RecordType = enum{
    P,
    PN,
    PC
};

pub const PRecord =  struct {
    phone_number: []u8 = std.mem.zeroes([@import("packet_buffer.zig").e164_max_phone_number_len]u8),
    provider_name: []u8,
    provider_code: []u8,
    ttl: u32,
};

const PNRecord = struct {};
const PCRecord = struct {};

pub const DnsRecord = union(RecordType){
    P: PRecord,
    PN:PNRecord,
    PC: PCRecord,

    pub fn read(this: *DnsRecord, _: *DNSPacketBuffer) DnsRecord {
        switch (this) {
            .P => std.log.info("P"),
            else => unreachable,
        }
     
    //  var e164_phone_number = std.ArrayList(u8).init(allocator);
    //  defer allocator.free(e164_phone_number);
    //  defer e164_phone_number.deinit();

    //  try buffer.read(e164_phone_number);
    //  this.PResponse =  PQueryResponseRecord {
    //      .phone_number = e164_phone_number,
         
    //  }
 }
};

