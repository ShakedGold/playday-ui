const std = @import("std");

const playday_api = @import("playday_api");

const log = std.log.scoped(.metadata_store);

var providers: std.ArrayList(playday_api.metadata.MetadataProvider) = .empty;
var metadata_games: std.StringHashMap(playday_api.models.extra_metadata.ExtraGameMetadata) = undefined;

pub fn init(allocator: std.mem.Allocator, io: std.Io) !void {
    // TODO: add a way to add providers
    // TODO: remove demo provider

    try providers.append(
        allocator,
        try .init(io, allocator, .steam_store),
    );

    metadata_games = .init(allocator);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    for (providers.items) |*provider| {
        provider.deinit();
    }

    providers.deinit(allocator);

    var iter = metadata_games.valueIterator();
    while (iter.next()) |entry| {
        entry.deinit(allocator);
    }

    metadata_games.deinit();
}

pub fn refreshMetadata(games: []const playday_api.models.game.Game, allocator: std.mem.Allocator, io: std.Io) !void {
    for (games) |*game| {
        try metadata_games.put(game.id, try getMetadata(game, allocator, io));
    }
}

pub fn getMetadata(game: *const playday_api.models.game.Game, allocator: std.mem.Allocator, io: std.Io) !playday_api.models.extra_metadata.ExtraGameMetadata {
    log.debug("Searching for metadata for {s} ({s})", .{ game.id, game.name });
    return playday_api.models.extra_metadata.getMetadata(game.id, allocator, io) catch |err| switch (err) {
        error.MetadataNotFound => {
            log.err("Failed finding metadata for {s} in DB", .{game.name});
            return getMetadataFromProviders(game);
        },
        else => return err,
    };
}

fn getMetadataFromProviders(game: *const playday_api.models.game.Game) !playday_api.models.extra_metadata.ExtraGameMetadata {
    log.debug("Searching for the game's metadata in the providers", .{});

    for (providers.items) |*provider| {
        return provider.getMetadata(game.id) catch |err| {
            log.err("Failed finding metadata for {s} in provider: {s}", .{ game.name, @tagName(provider.*) });
            log.err("Error: {}", .{err});
            continue;
        };
    }

    return error.MetadataNotFound;
}
