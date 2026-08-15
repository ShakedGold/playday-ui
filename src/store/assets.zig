const std = @import("std");

const Asset = enum {
    default_icon,

    fn path(self: Asset) []const u8 {
        return comptime switch (self) {
            .default_icon => "assets/default_icon.png",
        };
    }
};

pub var assetFiles: std.EnumMap(Asset, []u8) = .init(.{});

pub fn init(io: std.Io, allocator: std.mem.Allocator) !void {
    inline for (std.enums.values(Asset)) |asset| {
        const file = try std.Io.Dir.cwd().openFile(io, asset.path(), .{});
        defer file.close(io);

        const stat = try file.stat(io);
        const buffer = try allocator.alloc(u8, stat.size);

        const amount_read = try file.readPositionalAll(io, buffer, 0);
        if (amount_read != stat.size) {
            return error.NotEnoughBytesRead;
        }

        assetFiles.put(asset, buffer);
    }
}

pub fn deinit(allocator: std.mem.Allocator) void {
    for (assetFiles.values) |asset| {
        allocator.free(asset);
    }
}
