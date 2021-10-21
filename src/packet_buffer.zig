const ArrayList = @import("std").ArrayList;
const FixedBufferAllocator = @import("std").heap.FixedBufferAllocator;
const std = @import("std");
const mem = std.mem;

pub const dns_packet_size = 512;
pub const e164_max_phone_number_len = 15;

pub const ReadPacketError = error{ EOF, InvalidPhoneNumber, EmptyPacket, InvalidPacket };

pub const DNSPacketBuffer = struct {
    buffer: []u8,
    cursor: usize = 0,

    pub fn step(this: *DNSPacketBuffer, steps: usize) void {
        this.cursor += steps;
    }

    pub fn pos(this: *DNSPacketBuffer) usize {
        return this.cursor;
    }

    pub fn seek(this: *DNSPacketBuffer, index: usize) void {
        this.cursor = index;
    }

    pub fn get(this: *DNSPacketBuffer) ReadPacketError!u8 {
        if (this.buffer.len < 1) return ReadPacketError.EmptyPacket;
        if (this.cursor >= dns_packet_size) return ReadPacketError.EOF;
        return this.buffer[this.cursor];
    }

    pub fn read(this: *DNSPacketBuffer) ReadPacketError!u8 {
        const res = this.get();
        this.cursor += 1;
        return res;
    }

    pub fn getRange(this: *DNSPacketBuffer, start: usize, len: usize) ReadPacketError![]u8 {
        if (this.buffer.len < 1) return ReadPacketError.EmptyPacket;
        if (start + len >= dns_packet_size) return ReadPacketError.EOF;
        return this.buffer[start..start+len];
    }

    pub fn readU16(this: *DNSPacketBuffer) ReadPacketError!u16 {
        return (@as(u16, try this.read()) << 8 )| @as(u16, try this.read());
    }

    pub fn readU32(this: *DNSPacketBuffer) ReadPacketError!u32 {
        return (@as(u32, try this.read()) << 24) 
        | (@as(u32,try this.read()) << 16) 
        | (@as(u32, try this.read()) << 8) 
        | @as(u32, try this.read());
    }

    //: QNAME
    pub fn readPhoneNumber(this: *DNSPacketBuffer, e164_phone_number: *ArrayList(u8) ) anyerror!void {
        
        var len = try this.get();
        while ( len != 0): (len = try this.get()) {
            this.seek(this.pos() + 1);
           try e164_phone_number.appendSlice(try this.getRange(this.pos(),len));
            this.step(len);
        }

    }
};
