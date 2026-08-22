const std = @import("std");
const Io = std.Io;

const components = @import("components");
const dvui = @import("dvui");
pub const panic = dvui.App.panic;
const playday_api = @import("playday_api");
const store = @import("store");

var initGlobal: std.process.Init = undefined;

/// Split position of the sidebar pane [0-1] of the window width.
/// Starts at 10%, and is kept at 5% minimum by clamping after event processing.
var sidebar_split: f32 = 0.10;

var tasks: std.Io.Group = .init;

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
    try components.mainMenu(initGlobal.io, initGlobal.gpa, &tasks);

    const panedWidget = dvui.paned(
        @src(),
        .{
            .direction = .horizontal,
            .collapsed_size = 0,
            .split_ratio = &sidebar_split,
        },
        .{
            .expand = .both,
            .background = true,
        },
    );
    sidebar_split = @max(sidebar_split, 0.15);
    defer panedWidget.deinit();

    if (panedWidget.showFirst()) {
        components.gameSidebar();
    }

    if (panedWidget.showSecond()) {
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

    // This is bad, it causes a crash most of the time if while we fetch data we call cancel (e.g. refreshMetadata -> closing the window)
    // However since it is at the end of everything, it is mostly fine (still is there is a better way to not crash while closing the window, that will be preferable :D)
    tasks.cancel(initGlobal.io);
}
