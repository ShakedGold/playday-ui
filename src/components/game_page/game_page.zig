const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

const game_body = @import("game_body.zig");
const game_header = @import("game_header.zig");

pub fn gamePage(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    var scroll = dvui.scrollArea(@src(), .{}, .{ .background = false, .expand = .horizontal });
    defer scroll.deinit();

    var overlay = dvui.overlay(@src(), .{ .expand = .both });
    defer overlay.deinit();

    gameBackground(game);

    {
        var content = dvui.box(@src(), .{ .dir = .vertical }, .{
            .expand = .both,
        });
        defer content.deinit();

        game_header.banner(game);
        try game_body.details(game, io, allocator);
    }
}

fn gameBackground(game: *const playday_api.models.game.Game) void {
    _ = game; // autofix

    {
        var background = dvui.box(@src(), .{}, .{
            .background = true,
            .color_fill = .blue,
            .min_size_content = .height(10000), // TODO: Remove
            .expand = .both,
        });
        defer background.deinit();
    }

    {
        // TODO: Add the game's hero as an image and set the shrink to .ratio, based on the horizontal space left
        var hero = dvui.box(@src(), .{}, .{
            .background = true,
            .color_fill = .red,
            .min_size_content = .height(1240), // TODO: Remove
            .expand = .horizontal,
        });
        defer hero.deinit();
    }
}
