const std = @import("std");

const playday_api = @import("playday_api");

const log = std.log.scoped(.game_store);

var libraries: std.ArrayList(playday_api.libraries.library.Library) = .empty;

pub var games: std.ArrayList(playday_api.models.game.Game) = .empty;
pub var selectedGame: ?*const playday_api.models.game.Game = null;

// TODO: remove
var api: playday_api.libraries.steam.web_api.SteamAPI = undefined;
var local: playday_api.libraries.steam.local.SteamLocal = undefined;

pub fn init(io: std.Io, allocator: std.mem.Allocator, environ_map: *std.process.Environ.Map) !void {
    var dbGames = try playday_api.models.game.getGames(allocator, io);
    defer dbGames.deinit(allocator);

    try games.appendSlice(allocator, dbGames.items);

    // TODO: Find a way to add libraries
    // TODO: Remove

    const steam_key = environ_map.get("STEAM_KEY") orelse return error.SteamKeyNotFound;
    const steam_id = environ_map.get("STEAM_ID") orelse return error.SteamIdNotFound;

    api = .init(io, allocator, steam_key, steam_id);
    local = try .init(io, allocator, environ_map);

    try libraries.append(allocator, .init(.steam, .{ &api, &local }));
}

pub fn deinit(allocator: std.mem.Allocator) void {
    for (games.items) |*game| {
        game.deinit(allocator);
    }

    games.deinit(allocator);

    if (selectedGame != null) {
        selectedGame.? = undefined;
    }

    for (libraries.items) |*library| {
        library.deinit();
    }

    libraries.deinit(allocator);
}

fn refreshLibrary(library: *playday_api.libraries.library.Library, io: std.Io, allocator: std.mem.Allocator) !void {
    const retrievedGames = try library.getGames(io, allocator);
    defer allocator.free(retrievedGames);

    const duplicatedGames = try extend(retrievedGames, io, allocator);
    defer allocator.free(duplicatedGames);
}

fn refreshGamesTask(library: *playday_api.libraries.library.Library, io: std.Io, allocator: std.mem.Allocator) void {
    refreshLibrary(library, io, allocator) catch |err| {
        log.err("Failed to refresh the library: {s}, with {}", .{ @tagName(library.*), err });
    };
}

/// Refreshes the games by calling each library's refresh method
pub fn refresh(io: std.Io, allocator: std.mem.Allocator) !void {
    var libraryGroups: std.Io.Group = .init;
    defer libraryGroups.cancel(io);

    for (libraries.items) |*library| {
        try libraryGroups.concurrent(io, refreshGamesTask, .{ library, io, allocator });
    }

    try libraryGroups.await(io);
}

/// Returns an slice of the items that were duplicated, the caller owns the slice
pub fn extend(addedGames: []?playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) ![]playday_api.models.game.Game {
    var duplicatedGames: std.ArrayList(playday_api.models.game.Game) = .empty;

    gameLoop: for (addedGames) |*game| {
        if (game.*) |*currentGame| {
            for (games.items) |*storeGame| {
                if (std.mem.eql(u8, currentGame.id, storeGame.id)) {
                    try duplicatedGames.append(allocator, currentGame.*);
                    continue :gameLoop;
                }
            }

            try currentGame.insert(io, allocator);
            try games.append(allocator, currentGame.*);
        }
    }

    return duplicatedGames.toOwnedSlice(allocator);
}

pub fn run(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    try game.library.run(io, allocator, game);
}
