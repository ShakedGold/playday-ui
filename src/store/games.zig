const playday_api = @import("playday_api");

pub var games: ?[]const playday_api.models.game.Game = null;
pub var selectedGame: ?*const playday_api.models.game.Game = null;
