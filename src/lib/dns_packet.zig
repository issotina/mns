const std = @import("std");
const DNSHeader = @import("dns_header.zig").DNSHeader;
const DNSQuestion = @import("dns_query.zig").DNSQuestion;
const DnsRecord = @import("dns_record.zig").DnsRecord;
const NSRecord = @import("dns_record.zig").NSRecord;
const PRecord = @import("dns_record.zig").PRecord;
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError = @import("packet_buffer.zig").ReadPacketError;
const ArrayList = std.ArrayList;
        const allocator = std.heap.page_allocator;
        const e164_max_phone_number_len = @import("packet_buffer.zig").e164_max_phone_number_len;


pub const DNSPacket = struct {
    header: DNSHeader,
    questions: ArrayList(DNSQuestion),
    answers: ArrayList(DnsRecord),
    authorities: ArrayList(DnsRecord),
    resources: ArrayList(DnsRecord),

    pub fn write(this: *DNSPacket, buffer: *DNSPacketBuffer) anyerror!void {
        this.header.questions_entries = @truncate(u16, this.questions.items.len);
        this.header.answers_entries = @truncate(u16, this.answers.items.len);
        this.header.authoritative_entries = @truncate(u16, this.authorities.items.len);
        this.header.resource_entries = @truncate(u16, this.resources.items.len);

        try this.header.write(buffer);

        for (this.questions.items) |question| {
            try question.write(buffer);
        }

        for (this.answers.items) |r| {
            try r.write(buffer);
        }
        for (this.authorities.items) |r| {
            try r.write(buffer);
        }
        for (this.resources.items) |r| {
            try r.write(buffer);
        }
    }

    pub fn fromBuffer(this: *DNSPacket, buffer: *DNSPacketBuffer) anyerror!void {
        try this.header.read(buffer);

        var i = this.header.questions_entries;
        while (i > 0) : (i -= 1) {
            var question = DNSQuestion{ .phone_number = try allocator.alloc(u8, e164_max_phone_number_len)};
            try question.read(buffer);
            try this.questions.append(question);
        }
    }
};
