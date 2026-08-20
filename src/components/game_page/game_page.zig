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

    try gameBackground(game);

    {
        var content = dvui.box(@src(), .{ .dir = .vertical }, .{
            .expand = .both,
        });
        defer content.deinit();

        game_header.banner(game);
        try game_body.details(game, io, allocator);
    }
}

fn gameBackground(game: *const playday_api.models.game.Game) !void {
    {
        var background = dvui.box(@src(), .{}, .{
            .background = true,
            .color_fill = .blue,
            .expand = .both,
        });
        defer background.deinit();
    }

    {
        var box = dvui.box(@src(), .{}, .{
            .expand = .both,
            .background = true,
            .color_fill = .black,
        });
        defer box.deinit();

        if (game.hero) |hero| {
            const source: dvui.ImageSource = .{ .imageFile = .{ .bytes = hero } };

            _ = dvui.image(
                @src(),
                .{
                    .source = source,
                    .shrink = .none,
                },
                .{
                    .gravity_x = 0.5,
                    .max_size_content = .height(box.wd.rect.h),
                },
            );
        }
    }
}
