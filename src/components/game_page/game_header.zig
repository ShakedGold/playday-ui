const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

const banner_max_height = 350;

pub fn banner(game: *const playday_api.models.game.Game) void {
    var bannerBox = dvui.box(@src(), .{}, .{
        .min_size_content = .height(banner_max_height),
        .expand = .horizontal,
    });
    defer bannerBox.deinit();

    if (game.logo) |logo| {
        _ = dvui.image(
            @src(),
            .{ .source = .{ .imageFile = .{ .bytes = logo } }, .shrink = .ratio },
            .{
                .gravity_x = 0.5,
                .gravity_y = 0.5,
                .max_size_content = .height(banner_max_height),
            },
        );
    } else {
        dvui.label(@src(), "{s}", .{game.name}, .{
            .gravity_x = 0.5,
            .gravity_y = 0.5,
        });
    }
}
