const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError = @import("packet_buffer.zig").ReadPacketError;
const WritePacketError = @import("packet_buffer.zig").WritePacketError;


pub const ResultCode = enum(u4) {
    NOERROR,
    FORMERR,
    SERVFAIL,
    NXDOMAIN,
    NOTIMP,
    REFUSED,
    NOTZONE,

    pub fn parse(num: u8) ResultCode {
        return switch (num) {
            1 => ResultCode.NOERROR,
            2 => ResultCode.FORMERR,
            3 => ResultCode.SERVFAIL,
            4 => ResultCode.NXDOMAIN,
            5 => ResultCode.NOTIMP,
            9 => ResultCode.NOTZONE,
            else => ResultCode.NOERROR,
        };
    }
};

pub const DNSHeader = struct {
    id: u16 = 0,
    recursion_desired: bool = false,
    truncated_message: bool = false,
    authoritative_answer: bool = false,
    opcode: u8 = 0,
    response: bool = false,
    rescode: ResultCode = ResultCode.NOERROR,
    checking_disabled: bool = false,
    authed_data: bool = false,
    z: bool = false,
    recursion_available: bool = false,
    questions_entries: u16 = 0,
    answers_entries: u16 = 0,
    authoritative_entries: u16 = 0,
    resource_entries: u16 = 0,

    pub fn read(this: *DNSHeader, buffer: *DNSPacketBuffer) ReadPacketError!void {
        this.id = try buffer.readU16();
        var flags = try buffer.readU16();
        var a = @truncate(u8, (flags >> 8));
        var b = @truncate(u8, (flags & 0xFF));
        this.recursion_desired = (a & (1 << 0)) > 0;
        this.truncated_message = (a & (1 << 1)) > 0;
        this.authoritative_answer = (a & (1 << 2)) > 0;
        this.opcode = (a >> 3) & 0x0F;
        this.response = (a & (1 << 7)) > 0;

        this.rescode = ResultCode.parse(b & 0x0F);
        this.checking_disabled = (b & (1 << 4)) > 0;
        this.authed_data = (b & (1 << 5)) > 0;
        this.z = (b & (1 << 6)) > 0;
        this.recursion_available = (b & (1 << 7)) > 0;

        this.questions_entries = try buffer.readU16();
        this.answers_entries = try buffer.readU16();
        this.authoritative_entries = try buffer.readU16();
        this.resource_entries = try buffer.readU16();
    }


    pub fn write(this: *DNSHeader, buffer: *DNSPacketBuffer) WritePacketError!void {
        try buffer.writeU16(this.id);

        try buffer.write(
            @as(u8,@boolToInt(this.recursion_desired))
                | ( @as(u8, @boolToInt(this.truncated_message)) << 1)
                | ( @as(u8,@boolToInt(this.authoritative_answer)) << 2)
                | (this.opcode << 3)
                | @as(u8, @as(u8,@boolToInt(this.response)) << 7),
        );

        try buffer.write(
            @as(u8,@enumToInt(this.rescode))
                | ( @as(u8,@boolToInt(this.checking_disabled)) << 4)
                | ( @as(u8,@boolToInt(this.authed_data)) << 5)
                | ( @as(u8, @boolToInt(this.z)) << 6)
                | ( @as(u8,@boolToInt(this.recursion_available)) << 7),
        );

        try buffer.writeU16(this.questions_entries);
        try buffer.writeU16(this.answers_entries);
        try buffer.writeU16(this.authoritative_entries);
        try buffer.writeU16(this.resource_entries);
    }
};
