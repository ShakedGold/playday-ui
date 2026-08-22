const std = @import("std");

const dvui = @import("dvui");
const store = @import("store");

const InitOptions = struct { button_init_options: dvui.ButtonWidget.InitOptions, gravity_x: ?f32, gravity_y: ?f32 };

const GameButtonOptions = struct {
    icon_options: dvui.Options,
    button_options: dvui.Options,
};

// Source: https://david-vanderson.github.io/docs/#dvui.button
pub fn game_button(src: std.builtin.SourceLocation, label_str: []const u8, icon_bytes: ?[]const u8, init_opts: InitOptions, options: GameButtonOptions) bool {
    // initialize widget and get rectangle from parent and make ourselves the new parent
    var bw: dvui.ButtonWidget = undefined;

    bw.init(src, init_opts.button_init_options, options.button_options);

    // process events (mouse and keyboard)
    bw.processEvents();

    // draw background/border
    bw.drawBackground();

    {
        var hbox = dvui.box(src, .{ .dir = .horizontal }, .{ .expand = .horizontal });
        defer hbox.deinit();

        const icon = if (icon_bytes != null) icon_bytes.? else store.assetsStore.assetFiles.get(.default_icon).?;
        _ = dvui.image(
            @src(),
            .{ .source = .{ .imageFile = .{ .bytes = icon, .name = label_str } }, .shrink = .ratio },
            options.icon_options,
        );

        _ = dvui.spacer(@src(), .{ .min_size_content = .width(10) });

        dvui.labelNoFmt(@src(), label_str, .{ .align_x = 0.5, .align_y = 0.5 }, options.button_options.strip().override(bw.style()).override(.{ .gravity_x = init_opts.gravity_x, .gravity_y = init_opts.gravity_y }));
    }

    // use pressed text color if desired
    const click = bw.clicked();

    // draw focus
    bw.drawFocus();

    // restore previous parent
    // send our min size to parent
    bw.deinit();

    return click;
}
