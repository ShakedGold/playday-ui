const std = @import("std");

const playday_api = @import("playday_api");

const log = std.log.scoped(.game_store);

var libraries: std.ArrayList(playday_api.libraries.library.Library) = .empty;
var metadataProviders: std.ArrayList(playday_api.metadata.MetadataProvider) = .empty;

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

    // TODO: Find a way to add providers
    // TODO: Remove
    const igdb_secret = environ_map.get("IGDB_SECRET") orelse return error.IGDBSecretNotFound;
    const igdb_id = environ_map.get("IGDB_ID") orelse return error.IGDBIdNotFound;

    // try metadataProviders.append(allocator, .init(io, allocator, .steam_store, .{}));
    try metadataProviders.append(allocator, .init(io, allocator, .igdb, .{ .id = igdb_id, .secret = igdb_secret }));
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

    for (metadataProviders.items) |*provider| {
        provider.deinit();
    }

    metadataProviders.deinit(allocator);
}

fn refreshLibrary(library: *playday_api.libraries.library.Library, io: std.Io, allocator: std.mem.Allocator) !void {
    const retrievedGames = try library.getGames(io, allocator);
    defer allocator.free(retrievedGames);

    const duplicatedGames = try extend(retrievedGames, io, allocator);

    for (duplicatedGames) |*game| {
        game.deinit(allocator);
    }
    allocator.free(duplicatedGames);
}

fn refreshGamesTask(library: *playday_api.libraries.library.Library, io: std.Io, allocator: std.mem.Allocator) void {
    refreshLibrary(library, io, allocator) catch |err| {
        log.err("Failed to refresh the library: {s}, with {}", .{ @tagName(library.*), err });
    };
}

/// Refreshes the games by calling each library's refresh method
pub fn refresh(io: std.Io, allocator: std.mem.Allocator, tasks: *std.Io.Group) !void {
    for (libraries.items) |*library| {
        try tasks.concurrent(io, refreshGamesTask, .{ library, io, allocator });
    }
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

fn refreshMetadataTask(game: *playday_api.models.game.Game, index: usize) void {
    _ = index;

    for (metadataProviders.items) |*provider| {
        var gameRefresher = provider.refresher(game);
        defer gameRefresher.deinit();

        if (game.logo == null) {
            _ = gameRefresher.refreshLogo() catch |err| {
                log.err("Error while fetching description: {}", .{err});
            };
        }

        if (game.icon == null) {
            _ = gameRefresher.refreshIcon() catch |err| {
                log.err("Error while fetching description: {}", .{err});
            };
        }

        if (game.hero == null) {
            _ = gameRefresher.refreshHero() catch |err| {
                log.err("Error while fetching description: {}", .{err});
            };
        }

        if (game.grid == null) {
            _ = gameRefresher.refreshGrid() catch |err| {
                log.err("Error while fetching description: {}", .{err});
            };
        }

        if (game.description == null) {
            _ = gameRefresher.refreshDescription() catch |err| {
                log.err("Error while fetching description: {}", .{err});
            };
        }
    }
}

fn refreshMetadataManagerTask(io: std.Io) void {
    const concurrency: playday_api.utils.async.BoundedConcurrency(playday_api.models.game.Game) = .{
        .batch_size = 25,
        .items = games.items,
    };

    concurrency.processAll(io, refreshMetadataTask, .{}) catch |err| {
        log.err("Error while processing refresh metadata tasks: {}", .{err});
    };
}

pub fn refreshMetadata(io: std.Io, tasks: *std.Io.Group) !void {
    tasks.async(io, refreshMetadataManagerTask, .{io});
}
