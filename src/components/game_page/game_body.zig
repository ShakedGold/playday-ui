const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

pub fn details(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    var detailsBox = dvui.box(@src(), .{}, .{
        .background = true,
        .color_fill = .opacity(.gray, 0.8),
        .expand = .both,
    });
    defer detailsBox.deinit();

    var statsBox = dvui.box(@src(), .{ .dir = .horizontal }, .{
        .min_size_content = .height(70),
        .expand = .horizontal,
        .background = true,
        .color_fill = .opacity(.black, 0.5),
    });
    defer statsBox.deinit();

    {
        const run = dvui.button(@src(), if (game.installed_location != null) "Play" else "Install", .{}, .{
            .expand = .vertical,
            .margin = .all(10),
            .min_size_content = .width(150),
            .background = true,
            .color_fill = .blue,
        });

        if (run) {
            try store.gamesStore.run(game, io, allocator);
        }
    }
}
