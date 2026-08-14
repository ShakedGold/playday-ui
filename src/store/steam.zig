const std = @import("std");
const playday_api = @import("playday_api");

var api: playday_api.libraries.steam.web_api.SteamAPI = undefined;
pub var library: playday_api.libraries.steam.library.SteamLibrary = .{ .steamAPI = &api };

pub fn init(io: std.Io, allocator: std.mem.Allocator, key: []const u8, steamid: []const u8) void {
    api = .init(io, allocator, key, steamid);
}

pub fn deinit() void {
    api.deinit();
}
