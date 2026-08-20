const std = @import("std");

const dvui = @import("dvui");
const playday_api = @import("playday_api");
const store = @import("store");

fn formatMinutes(minutes: u32) struct { value: u32, unit: []const u8 } {
    if (minutes >= 60) {
        return .{
            .value = minutes / 60,
            .unit = "hours",
        };
    }

    return .{
        .value = minutes,
        .unit = "minutes",
    };
}

fn formatDate(secondsSinceEpoch: u64, buf: []u8) ![]u8 {
    const epoch = std.time.epoch.EpochSeconds{
        .secs = secondsSinceEpoch,
    };
    const epoch_day = epoch.getEpochDay();

    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const months = [_][]const u8{
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    };

    return std.fmt.bufPrint(
        buf,
        "{s} {d}, {d}",
        .{
            months[@intFromEnum(month_day.month) - 1],
            month_day.day_index + 1,
            year_day.year,
        },
    );
}

pub fn details(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    var detailsBox = dvui.box(@src(), .{}, .{
        .background = true,
        .color_fill = .opacity(.gray, 0.8),
        .expand = .both,
    });
    defer detailsBox.deinit();

    var statsBox = dvui.box(@src(), .{ .dir = .horizontal }, .{
        .min_size_content = .height(70),
        .expand = .horizontal,
        .background = true,
        .color_fill = .opacity(.black, 0.5),
    });
    defer statsBox.deinit();

    {
        const run = dvui.button(@src(), if (game.installed_location != null) "Play" else "Install", .{}, .{
            .expand = .vertical,
            .margin = .all(10),
            .min_size_content = .width(150),
            .background = true,
            .color_fill = .green,
        });

        if (run) {
            try game.library.run(io, allocator, game);
        }
    }

    _ = dvui.spacer(@src(), .{ .min_size_content = .width(10) });

    {
        const last_played_box = dvui.box(@src(), .{ .dir = .vertical }, .{ .gravity_y = 0.5 });
        defer last_played_box.deinit();

        var last_played_buffer: [256]u8 = undefined;

        dvui.label(@src(), "LAST PLAYED", .{}, .{});
        dvui.label(@src(), "{s}", .{if (game.last_played) |last_played| try formatDate(last_played, last_played_buffer[0..]) else "Never"}, .{ .color_text = .fromHex("adadad") });
    }

    _ = dvui.spacer(@src(), .{ .min_size_content = .width(10) });

    {
        const play_time_box = dvui.box(@src(), .{ .dir = .vertical }, .{ .gravity_y = 0.5 });
        defer play_time_box.deinit();

        dvui.label(@src(), "PLAY TIME", .{}, .{});
        dvui.label(@src(), "{[value]d} {[unit]s}", formatMinutes(game.playtime), .{ .color_text = .fromHex("adadad") });
    }
}
