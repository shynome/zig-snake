const std = @import("std");
const ArrayList = std.ArrayList;
const mem = std.mem;
const testing = std.testing;

var rand: std.rand.Random = std.rand.Random{
    .fillFn = switch (true) {
        true => std.rand.DefaultPrng.init(0).random.fillFn,
        false => std.crypto.random.fillFn,
    },
};

pub const Point = struct {
    x: u8,
    y: u8,
    pub fn eql(self: *const Point, b: *const Point) bool {
        return self.x == b.x and self.y == b.y;
    }
    pub const MoveError = error{
        NoWayGo,
    };
    fn move(self: Point, direction: Direction) !Point {
        var nPoint = self;
        if (direction == Direction.Up and nPoint.y == 0) return MoveError.NoWayGo;
        if (direction == Direction.Left and nPoint.x == 0) return MoveError.NoWayGo;
        switch (direction) {
            .Up => nPoint.y -= 1,
            .Down => nPoint.y += 1,
            .Left => nPoint.x -= 1,
            .Right => nPoint.x += 1,
        }
        return nPoint;
    }
    pub fn position(self: *const Point, max: *const Point) usize {
        return self.y * max.x + self.x;
    }
};
pub const Direction = packed enum(u4) {
    Up,
    Down,
    Left,
    Right,
    pub fn random() Direction {
        var v = rand.intRangeLessThan(u8, 0, 4);
        return Direction.fromU4(v);
    }
    pub fn fromU4(v: u8) Direction {
        return switch (v) {
            0 => Direction.Up,
            1 => Direction.Down,
            2 => Direction.Left,
            3 => Direction.Right,
            else => unreachable,
        };
    }
};

pub const Map = struct {
    all: ArrayList(u8),
    empty: ArrayList(Point),
    max: Point,
    pub fn init(max: Point) Map {
        var all = ArrayList(u8).init(std.heap.page_allocator);
        var empty = ArrayList(Point).init(std.heap.page_allocator);
        var nx: u8 = 0;
        while (nx < max.x) : (nx += 1) {
            var ny: u8 = 0;
            while (ny < max.y) : (ny += 1) {
                empty.append(Point{ .x = nx, .y = ny }) catch unreachable;
                all.append(0) catch unreachable;
            }
        }
        return Map{
            .all = all,
            .empty = empty,
            .max = max,
        };
    }
    pub fn deinit(self: *const Map) void {
        self.all.deinit();
        self.empty.deinit();
    }
    pub fn fill(self: *Map, point: *const Point) void {
        self.all.replaceRange(point.position(&self.max), 1, &[_]u8{1}) catch unreachable;
        for (self.empty.items) |p, i| {
            if (point.eql(&p)) {
                _ = self.empty.swapRemove(i);
                return;
            }
        }
    }
    pub fn clean(self: *Map, point: Point) void {
        self.all.replaceRange(point.position(&self.max), 1, &[_]u8{0}) catch unreachable;
        self.empty.append(point) catch unreachable;
    }
    pub fn getRandomEmptyPoint(self: *const Map) Point {
        const i = rand.intRangeLessThan(u8, 0, @intCast(u8, self.empty.items.len));
        var point = self.empty.items[i];
        return point;
    }
    pub fn display(self: *const Map) []u8 {
        return self.all.items;
    }
};

pub const Snake = struct {
    max: Point,
    body: ArrayList(Point),
    map: Map,
    food: Point = Point{ .x = 0, .y = 0 },
    direction: Direction,
    const Self = @This();
    pub fn init(x: u8, y: u8) Self {
        const head = Point{
            .x = rand.intRangeAtMost(u8, 3, x - 3),
            .y = rand.intRangeAtMost(u8, 3, y - 3),
        };
        var direction = Direction.random();
        const nPoint = head.move(direction) catch unreachable;
        var body = ArrayList(Point).init(std.heap.page_allocator);
        body.appendSlice(&[_]Point{ nPoint, head }) catch unreachable;
        var max = Point{ .x = x, .y = y };
        var snake = Snake{
            .max = max,
            .body = body,
            .map = Map.init(max),
            .direction = direction,
        };
        for (body.items) |point| {
            snake.map.fill(&point);
        }
        snake.createFoodPoint();
        return snake;
    }
    pub fn deinit(self: *const Snake) void {
        self.body.deinit();
        self.map.deinit();
    }
    pub const DiedError = error{
        Overflow,
        EatBody,
    };
    pub const MoveError = error{
        NotAllowGoBack,
    };
    fn isSnakeBody(self: *const Snake, point: *const Point) bool {
        for (self.body.items) |snakePoint| {
            if (snakePoint.eql(point)) {
                return true;
            }
        }
        return false;
    }
    fn isOverflow(self: *const Snake, point: *const Point) bool {
        if (point.x < 0) {
            return true;
        }
        if (point.y < 0) {
            return true;
        }
        if (point.x > self.max.x - 1) {
            return true;
        }
        if (point.y > self.max.y - 1) {
            return true;
        }
        return false;
    }
    fn createFoodPoint(self: *Snake) void {
        var point = self.map.getRandomEmptyPoint();
        self.map.fill(&point);
        self.food = point;
    }
    fn isFoodPoint(self: *const Snake, point: *const Point) bool {
        return self.food.eql(point);
    }
    pub fn move(self: *Snake, direction: Direction) !void {
        const nextPoint = try self.body.items[0].move(direction);
        if (nextPoint.eql(&self.body.items[1])) {
            return MoveError.NotAllowGoBack;
        }
        if (self.isSnakeBody(&nextPoint)) {
            return DiedError.EatBody;
        }
        if (self.isOverflow(&nextPoint)) {
            return DiedError.Overflow;
        }
        self.direction = direction;
        self.eat(nextPoint);
    }
    pub fn eat(self: *Snake, nextPoint: Point) void {
        self.body.insert(0, nextPoint) catch unreachable;
        self.map.fill(&nextPoint);
        if (self.isFoodPoint(&nextPoint)) {
            self.createFoodPoint();
        } else {
            var endPoint = self.body.pop();
            self.map.clean(endPoint);
        }
    }
    pub fn keepMove(self: *Self) !void {
        try self.move(self.direction);
    }
};
