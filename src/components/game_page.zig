const dvui = @import("dvui");

const playday_api = @import("playday_api");

pub fn gamePage(game: *const playday_api.models.game.Game) void {
    dvui.label(@src(), "{s}", .{game.name}, .{});
}
