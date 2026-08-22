const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

const game_body = @import("game_body.zig");
const game_header = @import("game_header.zig");

const hero_height = 350;

pub fn gamePage(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    var scroll = dvui.scrollArea(@src(), .{}, .{ .background = false, .expand = .horizontal });
    defer scroll.deinit();

    var page = dvui.box(@src(), .{ .dir = .vertical }, .{ .expand = .both });
    defer page.deinit();

    {
        var hero = dvui.overlay(@src(), .{
            .expand = .horizontal,
            .min_size_content = .height(hero_height),
        });
        defer hero.deinit();

        try gameBackground(game);
        game_header.banner(game);
    }

    try game_body.detailBar(game, io, allocator);

    const bodyBox = dvui.box(@src(), .{ .dir = .horizontal }, .{});
    defer bodyBox.deinit();

    {
        game_body.details(game);
        try game_body.description(game);
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
            .max_size_content = .height(hero_height),
            .color_fill = .black,
        });
        defer box.deinit();

        if (game.hero) |hero| {
            const hero_box = dvui.box(@src(), .{}, .{
                .expand = .both,
            });
            defer hero_box.deinit();

            const source: dvui.ImageSource = .{
                .imageFile = .{ .bytes = hero },
            };

            const hero_rect = hero_box.data().contentRectScale().r;

            const old_clip = dvui.clip(hero_rect);
            defer dvui.clipSet(old_clip);

            _ = dvui.image(
                @src(),
                .{
                    .source = source,
                    .shrink = .none,
                },
                .{ .gravity_x = 0.5 },
            );
        }
    }
}
