usingnamespace @import("./snake.zig");
const std = @import("std");
const ArrayList = std.ArrayList;

var snake: Snake = undefined;

export fn init(x: u8, y: u8) void {
    snake = Snake.init(x, y);
}

export fn deinit(x: u8, y: u8) void {
    snake.deinit();
}

export fn move(direction: u8) MemPostision {
    snake.move(Direction.fromU4(direction)) catch |err| {
        return 1;
    };
    return 0;
}
export fn keepMove() MemPostision {
    snake.keepMove() catch |err| {
        return 1;
    };
    return 0;
}

const MemPostision = i64;
const ptrBase: MemPostision = 100_000_000;
fn memPostision(mem: anytype) MemPostision {
    if (mem.len > 0) {
        return @ptrToInt(&mem[0]) * ptrBase + mem.len;
    }
    return @ptrToInt(&mem) * ptrBase + mem.len;
}

fn displayPriv() MemPostision {
    var blocks = std.ArrayList(u8).init(std.heap.page_allocator);
    blocks.appendSlice(snake.map.all.items) catch |err| {};
    // // set food
    blocks.items[snake.food.position(&snake.max)] = 2;
    // // set head
    var headPosition = snake.body.items[0].position(&snake.max);
    blocks.items[headPosition] = 3;
    return memPostision(blocks.items);
}
export fn display() MemPostision {
    return displayPriv();
}
export fn hello() MemPostision {
    const z = "hello";
    return memPostision(z);
}
