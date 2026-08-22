const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

const components = @import("root.zig");

const log = std.log.scoped(.game_sidebar);

pub fn gameSidebar() void {
    var scroll = dvui.scrollArea(@src(), .{}, .{ .background = false, .expand = .horizontal });
    defer scroll.deinit();
    for (store.gamesStore.games.items, 0..) |game, index| {
        var isSelected = store.gamesStore.selectedGame == &store.gamesStore.games.items[index];

        isSelected = components.game_button(
            @src(),
            game.name[0..],
            game.icon,
            .{
                .gravity_x = 0,
                .gravity_y = 0.5,
                .button_init_options = .{ .grayed = game.installed_location == null, .draw_focus = false },
            },
            .{
                .icon_options = .{ .id_extra = index, .max_size_content = .all(35) },
                .button_options = .{
                    .id_extra = index,
                    .margin = .all(0),
                    .corners = .all(0),
                    .expand = .horizontal,
                    .background = true,
                    .color_fill_press = .{ .a = 100 },
                    .color_fill = if (isSelected) .{ .a = 100 } else null,
                },
            },
        );

        if (isSelected) {
            log.debug("selected game = {s}", .{game.name});
            store.gamesStore.selectedGame = &store.gamesStore.games.items[index];
        }
    }
}
