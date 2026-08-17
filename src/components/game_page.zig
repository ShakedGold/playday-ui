const std = @import("std");
const dvui = @import("dvui");

const store = @import("store");
const playday_api = @import("playday_api");

pub fn gamePage(game: *const playday_api.models.game.Game) !void {
    dvui.label(@src(), "Name: {s}", .{game.name}, .{});
    dvui.label(@src(), "ID: {s}", .{game.id}, .{});
    dvui.label(@src(), "Playtime: {d}", .{game.playtime}, .{});
    dvui.label(@src(), "Installed Directory: {s}", .{if (game.installed_location != null) game.installed_location.? else ""}, .{});

    const run = dvui.button(@src(), if (game.installed_location != null) "Run" else "Install", .{}, .{});
    if (run) {
        try store.steamStore.run(game);
    }
}
