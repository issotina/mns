const std = @import("std");
const  DNSPacket = @import("dns_packet.zig").DNSPacket;
const dns_packet_size = @import("packet_buffer.zig").dns_packet_size;
const DNSPacketBuffer = @import("packet_buffer.zig").DNSPacketBuffer;
const DNSHeader = @import("dns_header.zig").DNSHeader;
const DnsRecord = @import("dns_response.zig").DnsRecord;
const DNSQuestion = @import("dns_query.zig").DNSQuestion;
const allocator = std.heap.page_allocator;


pub fn main() anyerror!void {

  var file = try std.fs.cwd().openFile("/tmp/dns.txt",.{ .read = true });
  defer file.close();

 
  try file.seekTo(0);
  
  var pk_buffer = DNSPacketBuffer{
    .buffer = try file.readToEndAlloc(allocator, 512)
  };


  var pk = DNSPacket {
    .header = DNSHeader {},
    .questions = std.ArrayList(DNSQuestion).init(allocator),
    .answers = std.ArrayList(DnsRecord).init(allocator),
    .authorities = std.ArrayList(DnsRecord).init(allocator),
    .resources = std.ArrayList(DnsRecord).init(allocator),
  };
  pk.fromBuffer(&pk_buffer) catch |err| {
      std.debug.print("failed to read packet: {v}", .{err});
      @panic("");
  };

  std.debug.print("{s}",.{pk.questions.items[0].phone_number.items});
}


