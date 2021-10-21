const std = @import("std");
const DNSHeader = @import("dns_header.zig").DNSHeader;
const DNSQuestion = @import("dns_query.zig").DNSQuestion;
const DnsRecord = @import("dns_response.zig").DnsRecord;
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const ReadPacketError = @import("packet_buffer.zig").ReadPacketError;
const ArrayList = std.ArrayList;


pub const DNSPacket = struct {
    header:  DNSHeader,
    questions: ArrayList(DNSQuestion),
    answers: ArrayList(DnsRecord),
    authorities:ArrayList(DnsRecord),
    resources:ArrayList(DnsRecord),

    pub fn fromBuffer(this: *DNSPacket, buffer: *DNSPacketBuffer) anyerror!void {
       
          this.header.read(buffer) catch |err| {
             return err;
         };

        var i = this.header.questions_entries;
        while (i > 0) : (i -= 1) {
           var question = DNSQuestion{};
            try question.read(buffer);
            try this.questions.append(question);

        }

        // for _ in 0..result.header.answers {
        //     let rec = DnsRecord::read(buffer)?;
        //     result.answers.push(rec);
        // }
        // for _ in 0..result.header.authoritative_entries {
        //     let rec = DnsRecord::read(buffer)?;
        //     result.authorities.push(rec);
        // }
        // for _ in 0..result.header.resource_entries {
        //     let rec = DnsRecord::read(buffer)?;
        //     result.resources.push(rec);
        // }

        // Ok(result)
    }
};