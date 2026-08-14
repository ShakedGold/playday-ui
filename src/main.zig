const std = @import("std");
const dvui = @import("dvui");

const playday_api = @import("playday_api");
const components = @import("components");
const store = @import("store");

const Io = std.Io;

var debugAllocator: std.heap.DebugAllocator(.{}) = undefined;

pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = .{ .w = 800.0, .h = 600.0 },
            .title = "Playday",
            .window_init_options = .{
                .theme = dvui.Theme.builtin.adwaita_dark,
            },
        },
    },
    .frameFn = frame,
    .initFn = init,
    .deinitFn = deinit,
};

pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

pub fn frame() !dvui.App.Result {
    const panedWidget = dvui.paned(@src(), .{
        .direction = .horizontal,
        .collapsed_size = 0,
        .autofit_first = .{
            .min_split = 0.2, // First pane at least 20% of total width
            .min_size = 100, // First pane at least 100 logical pixels
        },
    }, .{
        .expand = .both,
    });
    defer panedWidget.deinit();

    if (panedWidget.showFirst()) {
        components.gameSidebar();
    }

    if (panedWidget.showSecond()) {
        const should_refresh_steam_games = dvui.button(@src(), "Refresh Steam Games", .{}, .{ .gravity_x = 1.0 });

        if (store.gamesStore.selectedGame == null) {
            var box = dvui.box(@src(), .{ .dir = .vertical }, .{ .expand = .both, .background = false });
            defer box.deinit();
        } else {
            components.gamePage(store.gamesStore.selectedGame.?);
        }

        if (should_refresh_steam_games) {
            const allocator = debugAllocator.allocator();
            var threaded: std.Io.Threaded = .init_single_threaded;
            const io = threaded.io();

            var webApiGames = try store.steamStore.library.getGames(allocator);
            defer webApiGames.deinit(allocator);

            const duplicateGames = try store.gamesStore.extendGames(webApiGames.items, io, allocator);
            for (duplicateGames) |*game| {
                game.deinit(allocator);
            }

            allocator.free(duplicateGames);
        }
    }

    return .ok;
}

pub fn init(window: *dvui.Window) !void {
    _ = window; //autofix
    debugAllocator = .init;

    const allocator = debugAllocator.allocator();
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

    store.steamStore.init(io, allocator, "3FEFC8754FB970CDCED1C085DE770699", "76561198369990015");

    var dbGames = try playday_api.models.game.getGames(allocator, io);
    defer dbGames.deinit(allocator);
    try store.gamesStore.games.appendSlice(allocator, dbGames.items);
}

pub fn deinit(window: *dvui.Window) void {
    _ = window; //autofix

    const allocator = debugAllocator.allocator();

    store.gamesStore.deinit(allocator);
    store.steamStore.deinit();

    _ = debugAllocator.deinit();
}
