const std = @import("std");

const log = std.log.scoped(.assets);

pub const default_icon = @embedFile("./assets/default_icon.png");
