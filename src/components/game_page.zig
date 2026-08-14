const dvui = @import("dvui");

const playday_api = @import("playday_api");

pub fn gamePage(game: *const playday_api.models.game.Game) void {
    dvui.label(@src(), "Name: {s}", .{game.name}, .{});
    dvui.label(@src(), "ID: {s}", .{game.id}, .{});
    dvui.label(@src(), "Playtime: {d}", .{game.playtime}, .{});
    dvui.label(@src(), "Icon: {s}", .{game.icon}, .{});
}
