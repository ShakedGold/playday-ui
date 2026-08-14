const std = @import("std");
const playday_api = @import("playday_api");

var api: playday_api.libraries.steam.web_api.SteamAPI = undefined;
var local: playday_api.libraries.steam.local.SteamLocal = undefined;
pub var library: playday_api.libraries.steam.library.SteamLibrary = .{ .steamAPI = &api, .steamLocal = &local };

pub fn init(initProcess: std.process.Init, key: []const u8, steamid: []const u8) !void {
    api = .init(initProcess.io, initProcess.gpa, key, steamid);
    local = try .init(initProcess.io, initProcess.gpa, initProcess.environ_map);
}

pub fn deinit() void {
    api.deinit();
    local.deinit();
}
