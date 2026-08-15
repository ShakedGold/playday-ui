const std = @import("std");
const dvui = @import("dvui");

const playday_api = @import("playday_api");

pub fn gamePage(allocator: std.mem.Allocator, io: std.Io, game: *const playday_api.models.game.Game) !void {
    dvui.label(@src(), "Name: {s}", .{game.name}, .{});
    dvui.label(@src(), "ID: {s}", .{game.id}, .{});
    dvui.label(@src(), "Playtime: {d}", .{game.playtime}, .{});
    dvui.label(@src(), "Installed Directory: {s}", .{if (game.installed_location != null) game.installed_location.? else ""}, .{});

    const run = dvui.button(@src(), if (game.installed_location != null) "Run" else "Install", .{}, .{});
    if (run) {
        const game_url = try std.fmt.allocPrint(
            allocator,
            "steam://rungameid/{s}",
            .{game.id},
        );
        defer allocator.free(game_url);

        var child = try std.process.spawn(io, .{
            .argv = &.{
                "steam",
                game_url,
            },
            .stderr = .ignore,
            .stdin = .ignore,
            .stdout = .ignore,
        });

        _ = try child.wait(io);
    }
}
