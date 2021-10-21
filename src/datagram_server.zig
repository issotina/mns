const std = @import("std");
const os = std.os;
const builtin = @import("builtin");

const is_windows = builtin.os.tag == .windows;
const is_darwin = builtin.os.tag.isDarwin();
const is_linux = builtin.os.tag == .linux;
const is_freebsd = builtin.os.tag == .freebsd;
const is_openbsd = builtin.os.tag == .openbsd;
const is_netbsd = builtin.os.tag == .netbsd;
const is_dragonfly = builtin.os.tag == .dragonfly;

const DGramServer = struct {
    sockfd: os.socket_t,
    listen_address: Address,

    pub fn init(options: Options) DGramServer {
         const nonblock = if (std.io.is_async) os.SOCK.NONBLOCK else 0;
        const sock_flags = os.SOCK_DGRAM | os.SOCK.CLOEXEC | nonblock;

        return DGramServer{
            .sockfd = null,
            .listen_address = undefined,
        };
    }

     pub fn listen(this: *DGramServer, address: Address) !void {
        const nonblock = if (std.io.is_async) os.SOCK.NONBLOCK else 0;
        const sock_flags = os.SOCK.STREAM | os.SOCK.CLOEXEC | nonblock;

        const sockfd = try try os.socket(os.AF_INET,sock_flags,@as(u32, 0));
        this.sockfd = sockfd;
        errdefer {
            os.closeSocket(sockfd);
            self.sockfd = null;
        }

        try os.bind(sockfd, &address.any, @sizeOf(os.sockaddr_in));
        try os.listen(sockfd, self.kernel_backlog);
        try os.getsockname(sockfd, &self.listen_address.any, &socklen);
    }
};
