const std = @import("std");

const dvui = @import("dvui");
const store = @import("store");

fn librarySubMenu(io: std.Io, allocator: std.mem.Allocator, tasks: *std.Io.Group) !bool {
    if (dvui.menuItemLabel(@src(), "Library", .{ .submenu = true }, .{ .expand = .horizontal })) |mainMenuClicked| {
        const mainSubmenu = dvui.floatingMenu(@src(), .{ .from = mainMenuClicked }, .{});
        defer mainSubmenu.deinit();

        if (dvui.menuItemLabel(@src(), "Refresh Games", .{}, .{ .expand = .horizontal })) |_| {
            try store.gamesStore.refresh(io, allocator, tasks);
            return true;
        }

        if (dvui.menuItemLabel(@src(), "Refresh Metadata", .{}, .{ .expand = .horizontal })) |_| {
            try store.gamesStore.refreshMetadata(io, allocator, tasks);
            return true;
        }
    }

    return false;
}

pub fn mainMenu(io: std.Io, allocator: std.mem.Allocator, tasks: *std.Io.Group) !void {
    const menu = dvui.menu(@src(), .horizontal, .{});
    defer menu.deinit();

    if (dvui.menuItemLabel(@src(), "M", .{ .submenu = true }, .{ .expand = .horizontal })) |mainMenuClicked| {
        const mainSubmenu = dvui.floatingMenu(@src(), .{ .from = mainMenuClicked }, .{});
        defer mainSubmenu.deinit();

        const should_close = try librarySubMenu(io, allocator, tasks);
        if (should_close) {
            mainSubmenu.close();
        }

        if (dvui.menuItemLabel(@src(), "Exit", .{}, .{ .expand = .horizontal })) |_| {
            std.process.exit(0);
        }
    }
}
