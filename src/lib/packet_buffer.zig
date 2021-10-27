const ArrayList = @import("std").ArrayList;
const FixedBufferAllocator = @import("std").heap.FixedBufferAllocator;
const std = @import("std");
const mem = std.mem;

pub const dns_packet_size = 512;
pub const e164_max_phone_number_len = 15;

pub const ReadPacketError = error{ EOF, InvalidPhoneNumber, EmptyPacket, InvalidPacket };
pub const WritePacketError = error{ EOF, InvalidIndex };

pub const DNSPacketBuffer = struct {
    buffer: []u8,
    cursor: usize = 0,

    pub fn toBuffer(this: *DNSPacketBuffer) []u8 {
        return this.buffer[0..this.pos()];
    }

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
        return this.buffer[start .. start + len];
    }

    pub fn readU16(this: *DNSPacketBuffer) ReadPacketError!u16 {
        return (@as(u16, try this.read()) << 8) | (@as(u16, try this.read()));
    }

    pub fn readU32(this: *DNSPacketBuffer) ReadPacketError!u32 {
        return (@as(u32, try this.read()) << 24) | (@as(u32, try this.read()) << 16) | (@as(u32, try this.read()) << 8) | @as(u32, try this.read());
    }

    pub fn set(this: *DNSPacketBuffer, index: usize, val: u8) WritePacketError!void {
        if (index >= dns_packet_size) return WritePacketError.InvalidIndex;
        this.buffer[index] = val;
    }

    pub fn setU16(this: *DNSPacketBuffer, index: usize, val: u16) WritePacketError!void {
        if (index >= dns_packet_size) return WritePacketError.InvalidIndex;
        try this.set(index, @truncate(u8, val >> 8));
        try this.set(index + 1, @truncate(u8, val & 0xFF));
    }

    pub fn write(this: *DNSPacketBuffer, val: u8) WritePacketError!void {
        if (this.pos() >= dns_packet_size) {
            return WritePacketError.EOF;
        }
        this.buffer[this.cursor] = val;
        this.cursor += 1;
    }

    pub fn writeU16(this: *DNSPacketBuffer, val: u16) WritePacketError!void {
        if (this.pos() >= dns_packet_size) return WritePacketError.InvalidIndex;
        try this.write(@truncate(u8, val >> 8));
        try this.write(@truncate(u8, val & 0xFF));
    }

    pub fn writeU32(this: *DNSPacketBuffer, val: u32) WritePacketError!void {
        try this.write(@truncate(u8, (val >> 24) & 0xFF));
        try this.write(@truncate(u8, (val >> 16) & 0xFF));
        try this.write(@truncate(u8, (val >> 8) & 0xFF));
        try this.write(@truncate(u8, (val >> 0) & 0xFF));
    }

    //: QNAME
    pub fn readQName(this: *DNSPacketBuffer,e164_phone_number: *[]u8 ) anyerror!void {
        var len = try this.get();
        var index: usize = 0;
        while (len != 0) : (len = try this.get()) {
            this.seek(this.pos() + 1);

            const slice = try this.getRange(this.pos(), len);
            for (slice) |v| {
                e164_phone_number.*[index] = v;
                index += 1;
            }
            this.step(len);
            len = try this.get();
             if ( len != @as(u8,0)) {
                e164_phone_number.*[index] = @as(u8, 46);
                index += 1;
            }
        }

        this.seek(this.pos() + 1);
        e164_phone_number.* = e164_phone_number.*[0..index];
 
    }

    pub fn writeQName(this: *DNSPacketBuffer, e164_phone_number: []const u8) anyerror!void {
        var it = std.mem.split(u8, e164_phone_number, ".");
        while (it.next()) |label| {
            try this.write(@truncate(u8, label.len));
            for (label) |b| {
                try this.write(b);
            }
        }

        try this.write(0);
    }
};
