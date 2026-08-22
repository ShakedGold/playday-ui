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

pub fn detailBar(game: *const playday_api.models.game.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    var detailsBox = dvui.box(@src(), .{}, .{
        .background = true,
        .color_fill = .opacity(.gray, 0.8),
        .expand = .horizontal,
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

pub fn description(game: *const playday_api.models.game.Game) !void {
    var descBox = dvui.box(@src(), .{}, .{ .expand = .both });
    defer descBox.deinit();

    const descriptionText = game.description orelse return;
    var buffer: [2048]u8 = undefined;
    const slice: []u8 = buffer[0..];

    var textLayout = dvui.textLayout(@src(), .{}, .{ .expand = .both });
    defer textLayout.deinit();

    const text = try std.fmt.bufPrint(slice, "{s}", .{descriptionText});
    textLayout.addText(text, .{});
}

pub fn details(game: *const playday_api.models.game.Game) void {
    var detailsBox = dvui.box(@src(), .{}, .{
        .expand = .both,
        .background = true,
    });
    defer detailsBox.deinit();

    dvui.label(@src(), "Details", .{}, .{});

    var col_widths: [2]f32 = @splat(0);

    var grid = dvui.grid(@src(), .colWidths(&col_widths), .{}, .{
        .expand = .horizontal,
        .background = false,
        .corners = .{ .tl = .square, .tr = .square, .br = .square, .bl = .square },
    });
    defer grid.deinit();

    // Both columns share the width equally.
    dvui.columnLayoutProportional(&.{ -1, -1 }, &col_widths, grid.data().contentRect().w);

    const Field = struct { name: []const u8, value: []const u8 };

    const fields = [_]Field{
        .{ .name = "Library", .value = @tagName(game.library) },
        .{ .name = "Installed Location", .value = game.installed_location orelse "Not Installed" },
    };

    for (fields, 0..) |field, row_num| {
        {
            var cell = grid.bodyCell(@src(), .colRow(0, row_num), .{});
            defer cell.deinit();

            var name_text = dvui.textLayout(@src(), .{}, .{ .expand = .both, .background = false });
            defer name_text.deinit();
            name_text.addText(field.name, .{ .color_text = .fromHex("adadad") });
        }

        {
            var cell = grid.bodyCell(@src(), .colRow(1, row_num), .{});
            defer cell.deinit();

            var value_scroll = dvui.scrollArea(@src(), .{ .horizontal = .auto, .vertical = .none }, .{
                .expand = .both,
                .background = false,
                // Reserve room for a line of text plus the horizontal scrollbar,
                // otherwise the scrollbar shrinks the viewport and clips the text.
                .min_size_content = .height(dvui.themeGet().font_body.lineHeight() + dvui.ScrollBarWidget.defaults.min_sizeGet().h),
            });
            defer value_scroll.deinit();

            var value_text = dvui.textLayout(@src(), .{}, .{ .expand = .both, .background = false });
            defer value_text.deinit();
            value_text.addText(field.value, .{});
        }
    }
}
