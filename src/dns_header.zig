const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError =@import("packet_buffer.zig").ReadPacketError;

pub const ResultCode = enum(u4) {
    NOERROR,
    FORMERR ,
    SERVFAIL,
    NXDOMAIN,
    NOTIMP,
    REFUSED,

    pub fn parse(num: u8) ResultCode {
        return switch (num) {
             1 =>  ResultCode.NOERROR,
             2 =>  ResultCode.FORMERR,
             3 =>  ResultCode.SERVFAIL,
             4 =>  ResultCode.NXDOMAIN,
             5 =>  ResultCode.NOTIMP,
            else =>  ResultCode.NOERROR
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

    pub fn read(this: *DNSHeader, buffer: *DNSPacketBuffer) ReadPacketError!void{
        this.id = try buffer.readU16() ;
        var flags = try buffer.readU16();
        var a = @truncate(u8, (flags >> 8));
        var b = @truncate(u8,(flags & 0xFF));
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
};
