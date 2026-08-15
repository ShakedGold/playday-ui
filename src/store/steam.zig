const std = @import("std");
const playday_api = @import("playday_api");
const store = @import("root.zig");

var gameTaskGroup: std.Io.Group = .init;

var api: playday_api.libraries.steam.web_api.SteamAPI = undefined;
var local: playday_api.libraries.steam.local.SteamLocal = undefined;
pub var library: playday_api.libraries.steam.library.SteamLibrary = .{ .steamAPI = &api, .steamLocal = &local };

pub fn init(initProcess: std.process.Init, key: []const u8, steamid: []const u8) !void {
    api = .init(initProcess.io, initProcess.gpa, key, steamid);
    local = try .init(initProcess.io, initProcess.gpa, initProcess.environ_map);
}

pub fn deinit(io: std.Io) void {
    gameTaskGroup.cancel(io);

    api.deinit();
    local.deinit();
}

fn refreshGamesTask(io: std.Io, allocator: std.mem.Allocator) void {
    const webApiGames = library.getGames(io, allocator) catch return;
    defer allocator.free(webApiGames);

    for (webApiGames) |*game| {
        if (game.*) |*currentGame| {
            store.gamesStore.addGame(currentGame, io, allocator) catch |err| switch (err) {
                error.DuplicatedGame => {
                    currentGame.deinit(allocator);
                    continue;
                },
                else => return,
            };
        }
    }
}

pub fn refreshGames(io: std.Io, allocator: std.mem.Allocator) !void {
    try gameTaskGroup.concurrent(io, refreshGamesTask, .{ io, allocator });
}
