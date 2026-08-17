const dvui = @import("dvui");

const playday_api = @import("playday_api");

pub fn banner(game: *const playday_api.models.game.Game) void {
    var bannerBox = dvui.box(@src(), .{}, .{
        .min_size_content = .height(350),
        .expand = .horizontal,
    });
    defer bannerBox.deinit();

    dvui.label(@src(), "{s}", .{game.name}, .{
        .gravity_x = 0.5,
        .gravity_y = 0.5,
    });
}
