const std = @import("std");
const dvui = @import("dvui");

const playday_api = @import("playday_api");
const components = @import("components");
const store = @import("store");

const Io = std.Io;

var initGlobal: std.process.Init = undefined;

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
    .frameFn = renderFrameWindow,
    .initFn = initWindow,
    .deinitFn = deinitWindow,
};

pub fn main(init: std.process.Init) !u8 {
    // we have to save this to a global because dvui does not pass it to us.
    initGlobal = init;

    return dvui.App.main(init);
}

pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

pub fn renderFrameWindow() !dvui.App.Result {
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
            try components.gamePage(store.gamesStore.selectedGame.?);
        }

        if (should_refresh_steam_games) {
            try store.steamStore.refreshGames(initGlobal.io, initGlobal.gpa);
        }
    }

    return .ok;
}

pub fn initWindow(window: *dvui.Window) !void {
    _ = window; //autofix
    try store.assetsStore.init(initGlobal.io, initGlobal.gpa);
    try store.steamStore.init(initGlobal, "3FEFC8754FB970CDCED1C085DE770699", "76561198369990015");
    try store.gamesStore.init(initGlobal.io, initGlobal.gpa);
}

pub fn deinitWindow(window: *dvui.Window) void {
    _ = window; //autofix

    store.assetsStore.deinit(initGlobal.gpa);
    store.gamesStore.deinit(initGlobal.gpa);
    store.steamStore.deinit(initGlobal.io);
}
