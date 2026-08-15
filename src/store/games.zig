const std = @import("std");
const playday_api = @import("playday_api");

var debugAllocator: std.heap.DebugAllocator(.{ .verbose_log = true }) = .init;

pub var games: std.ArrayList(playday_api.models.game.Game) = .empty;
pub var selectedGame: ?*const playday_api.models.game.Game = null;

pub fn init(io: std.Io, allocator: std.mem.Allocator) !void {
    var dbGames = try playday_api.models.game.getGames(allocator, io);
    defer dbGames.deinit(allocator);

    try games.appendSlice(allocator, dbGames.items);
}

pub fn addGame(game: *playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    for (games.items) |*storeGame| {
        if (std.mem.eql(u8, game.id, storeGame.id)) {
            return error.DuplicatedGame;
        }
    }

    try game.insert(io, allocator);
    try games.append(allocator, game.*);
}

/// Returns an slice of the items that were duplicated, the caller owns the slice
pub fn extendGames(addedGames: []playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) ![]playday_api.models.game.Game {
    var duplicatedGames: std.ArrayList(playday_api.models.game.Game) = .empty;

    gameLoop: for (addedGames) |*game| {
        for (games.items) |*storeGame| {
            if (std.mem.eql(u8, game.id, storeGame.id)) {
                try duplicatedGames.append(allocator, game.*);
                continue :gameLoop;
            }
        }

        try game.insert(io, allocator);
        try games.append(allocator, game.*);
    }

    return duplicatedGames.toOwnedSlice(allocator);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    for (games.items) |*game| {
        game.deinit(allocator);
    }

    games.deinit(allocator);

    if (selectedGame != null) {
        selectedGame.? = undefined;
    }
}
