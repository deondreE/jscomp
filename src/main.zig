const std = @import("std");
const Runtime = @import("runtime.zig").Runtime;
const Value = @import("value.zig").Value;
const ValueTag = @import("value.zig").ValueTag;

fn add(argc: usize, argv: []const Value) Value {
    if (argc < 2) return Value{ .undefined = {} };

    const a = argv[0].number;
    const b = argv[1].number;

    return Value{ .number = a + b };
}

fn multiply(argc: usize, argv: []const Value) Value {
    if (argc < 2) return Value{ .undefined = {} };

    const a = argv[0].number;
    const b = argv[1].number;

    return Value{ .number = a * b };
}

fn greet(argc: usize, argv: []const Value) Value {
    _ = argc;
    _ = argv;
    return Value{ .null = {} };
}

test "basic addition" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const add_fn = try rt.newFunction(&add);
    const args = [_]Value{
        Value{ .number = 2 },
        Value{ .number = 3 },
    };
    const result = rt.callFunction(add_fn, 2, args[0..]);

    try std.testing.expectEqual(ValueTag.number, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(f64, 5), result.number);
}

test "multiplication" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const mul_fn = try rt.newFunction(&multiply);
    const args = [_]Value{
        Value{ .number = 4 },
        Value{ .number = 5 },
    };
    const result = rt.callFunction(mul_fn, 2, args[0..]);

    try std.testing.expectEqual(ValueTag.number, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(f64, 20), result.number);
}

test "insufficient arguments returns undefined" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const add_fn = try rt.newFunction(&add);
    const args = [_]Value{Value{ .number = 10 }};
    const result = rt.callFunction(add_fn, 1, args[0..]);

    try std.testing.expectEqual(ValueTag.undefined, std.meta.activeTag(result));
}

test "create object" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const obj = try rt.newObject();
    try std.testing.expectEqual(ValueTag.object, std.meta.activeTag(obj));
}

test "function returning null" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const greet_fn = try rt.newFunction(&greet);
    const args = [_]Value{};
    const result = rt.callFunction(greet_fn, 0, args[0..]);

    try std.testing.expectEqual(ValueTag.null, std.meta.activeTag(result));
}

test "negative numbers" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const add_fn = try rt.newFunction(&add);
    const args = [_]Value{
        Value{ .number = -5 },
        Value{ .number = 3 },
    };
    const result = rt.callFunction(add_fn, 2, args[0..]);

    try std.testing.expectEqual(ValueTag.number, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(f64, -2), result.number);
}

test "floating point multiplication" {
    var rt = Runtime.init(std.testing.allocator);
    defer rt.deinit();

    const mul_fn = try rt.newFunction(&multiply);
    const args = [_]Value{
        Value{ .number = 2.5 },
        Value{ .number = 4.0 },
    };
    const result = rt.callFunction(mul_fn, 2, args[0..]);

    try std.testing.expectEqual(ValueTag.number, std.meta.activeTag(result));
    try std.testing.expectEqual(@as(f64, 10.0), result.number);
}

test "multiple runtime instances don't interfere" {
    var rt1 = Runtime.init(std.testing.allocator);
    defer rt1.deinit();

    var rt2 = Runtime.init(std.testing.allocator);
    defer rt2.deinit();

    const obj1 = try rt1.newObject();
    const obj2 = try rt2.newObject();

    try std.testing.expectEqual(ValueTag.object, std.meta.activeTag(obj1));
    try std.testing.expectEqual(ValueTag.object, std.meta.activeTag(obj2));
    try std.testing.expect(obj1.object != obj2.object);
}
