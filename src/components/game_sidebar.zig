const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

const components = @import("root.zig");

const log = std.log.scoped(.game_sidebar);

pub fn gameSidebar() void {
    var searchBuffer: [256]u8 = undefined;
    var searchableGameNameBuffer: [256]u8 = undefined;

    var search: []u8 = undefined;
    var gameName: []u8 = undefined;

    var scroll = dvui.scrollArea(@src(), .{}, .{ .background = false, .expand = .horizontal });
    defer scroll.deinit();

    var searchText: []u8 = undefined;

    {
        if (store.gamesStore.games.items.len == 0) {
            return;
        }

        const searchBar = dvui.textEntry(@src(), .{}, .{ .expand = .horizontal });
        defer searchBar.deinit();

        searchText = std.mem.sliceTo(searchBar.text, 0);
        search = std.ascii.lowerString(&searchBuffer, searchText);
    }

    for (store.gamesStore.games.items, 0..) |game, index| {
        if (searchText.len > 0) {
            gameName = std.ascii.lowerString(&searchableGameNameBuffer, game.name);
            const shouldDisplayGame = if (std.mem.count(u8, gameName, search) > 0) true else false;
            if (!shouldDisplayGame) {
                continue;
            }
        }

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
