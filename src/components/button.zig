const std = @import("std");
const dvui = @import("dvui");

const InitOptions = struct { button_init_options: dvui.ButtonWidget.InitOptions, gravity_x: ?f32, gravity_y: ?f32 };

// Source: https://david-vanderson.github.io/docs/#dvui.button
pub fn button(src: std.builtin.SourceLocation, label_str: []const u8, init_opts: InitOptions, opts: dvui.Options) bool {
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
