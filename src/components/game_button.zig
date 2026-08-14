const std = @import("std");
const dvui = @import("dvui");

const InitOptions = struct { button_init_options: dvui.ButtonWidget.InitOptions, gravity_x: ?f32, gravity_y: ?f32 };

const GameButtonOptions = struct {
    box_options: dvui.Options,
    icon_options: dvui.Options,
    button_options: dvui.Options,
};

pub fn game_button(src: std.builtin.SourceLocation, label_str: []const u8, icon_bytes: ?[]const u8, init_opts: InitOptions, options: GameButtonOptions) bool {
    var box = dvui.box(src, .{ .dir = .horizontal }, options.box_options);
    defer box.deinit();

    if (icon_bytes != null) {
        _ = dvui.image(@src(), .{ .source = .{ .imageFile = .{ .bytes = icon_bytes.?, .name = label_str } } }, options.icon_options);
    }
    return button(@src(), label_str, init_opts, options.button_options);
}

// Source: https://david-vanderson.github.io/docs/#dvui.button
fn button(src: std.builtin.SourceLocation, label_str: []const u8, init_opts: InitOptions, opts: dvui.Options) bool {
    // initialize widget and get rectangle from parent and make ourselves the new parent
    var bw: dvui.ButtonWidget = undefined;

    bw.init(src, init_opts.button_init_options, opts);

    // process events (mouse and keyboard)
    bw.processEvents();

    // draw background/border
    bw.drawBackground();

    // use pressed text color if desired
    const click = bw.clicked();

    // this child widget:
    // - has bw as parent
    // - gets a rectangle from bw
    // - draws itself
    // - reports its min size to bw
    dvui.labelNoFmt(@src(), label_str, .{ .align_x = 0.5, .align_y = 0.5 }, opts.strip().override(bw.style()).override(.{ .gravity_x = init_opts.gravity_x, .gravity_y = init_opts.gravity_y }));

    // draw focus
    bw.drawFocus();

    // restore previous parent
    // send our min size to parent
    bw.deinit();

    return click;
}
