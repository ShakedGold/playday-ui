const std = @import("std");
const Io = std.Io;

const components = @import("components");
const dvui = @import("dvui");
pub const panic = dvui.App.panic;
const playday_api = @import("playday_api");
const store = @import("store");

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
        {
            const box = dvui.box(@src(), .{ .dir = .horizontal }, .{ .expand = .horizontal });
            defer box.deinit();

            const should_refresh_games = dvui.button(@src(), "Refresh Games", .{}, .{ .gravity_x = 1.0 });
            const should_refresh_metadata = dvui.button(@src(), "Refresh Metadata", .{}, .{ .gravity_x = 1.0 });

            if (should_refresh_games) {
                try store.gamesStore.refresh(initGlobal.io, initGlobal.gpa);
            }

            if (should_refresh_metadata) {
                try store.gamesStore.refreshMetadata(initGlobal.io, initGlobal.gpa);
            }
        }

        if (store.gamesStore.selectedGame != null) {
            try components.gamePage(store.gamesStore.selectedGame.?, initGlobal.io, initGlobal.gpa);
        }
    }

    return .ok;
}

pub fn initWindow(window: *dvui.Window) !void {
    _ = window; //autofix

    try store.assetsStore.init(initGlobal.io, initGlobal.gpa);
    errdefer store.assetsStore.deinit(initGlobal.gpa);

    try store.gamesStore.init(initGlobal.io, initGlobal.gpa, initGlobal.environ_map);
    errdefer store.gamesStore.deinit(initGlobal.gpa);
}

pub fn deinitWindow(window: *dvui.Window) void {
    _ = window; // autofix

    store.assetsStore.deinit(initGlobal.gpa);
    store.gamesStore.deinit(initGlobal.gpa);
}
