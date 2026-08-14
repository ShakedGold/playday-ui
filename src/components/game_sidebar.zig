const std = @import("std");

const dvui = @import("dvui");
const components = @import("root.zig");
const store = @import("store");
const playday_api = @import("playday_api");

const log = std.log.scoped(.game_sidebar);

pub fn gameSidebar() void {
    var box = dvui.box(@src(), .{ .dir = .vertical }, .{ .expand = .both, .background = true, .color_fill = .red });
    defer box.deinit();

    var scroll = dvui.scrollArea(@src(), .{}, .{ .background = false, .expand = .horizontal });
    defer scroll.deinit();

    for (store.gamesStore.games.items, 0..) |game, index| {
        const isSelected = components.game_button(
            @src(),
            game.name[0..],
            game.icon,
            .{
                .gravity_x = 0,
                .gravity_y = 0.5,
                .button_init_options = .{},
            },
            .{
                .box_options = .{ .id_extra = index, .expand = .horizontal },
                .icon_options = .{ .id_extra = index },
                .button_options = .{
                    .id_extra = index,
                    .margin = .all(0),
                    .corners = .all(0),
                    .background = false,
                    .expand = .both,
                },
            },
        );

        if (isSelected) {
            log.debug("selected game = {s}", .{game.name});
            store.gamesStore.selectedGame = &store.gamesStore.games.items[index];
        }
    }
}
