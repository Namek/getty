const std = @import("std");
const getty = @import("getty");

const Token = @import("token.zig").Token;
const Serializer = @import("serializer.zig").Serializer;

test "array" {
    try t([_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t([_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "array list" {
    const allocator = std.testing.allocator;

    {
        var list = std.ArrayList(i32).init(allocator);
        defer getty.free(allocator, list);

        try t(list, &[_]Token{
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
        });
    }

    {
        var list = std.ArrayList(std.ArrayList(i32)).init(allocator);
        var a = std.ArrayList(i32).init(allocator);
        var b = std.ArrayList(i32).init(allocator);
        var c = std.ArrayList(i32).init(allocator);
        defer getty.free(allocator, list);

        try b.append(1);
        try c.append(2);
        try c.append(3);
        try list.appendSlice(&[_]std.ArrayList(i32){ a, b, c });

        try t(list, &[_]Token{
            // START list
            .{ .Seq = .{ .len = 3 } },

            // START a
            .{ .Seq = .{ .len = 0 } },
            .{ .SeqEnd = .{} },
            // END a

            // START b
            .{ .Seq = .{ .len = 1 } },
            .{ .I32 = 1 },
            .{ .SeqEnd = .{} },
            // END b

            // START c
            .{ .Seq = .{ .len = 2 } },
            .{ .I32 = 2 },
            .{ .I32 = 3 },
            .{ .SeqEnd = .{} },
            // END c

            .{ .SeqEnd = .{} },
            // END list
        });
    }
}

test "bool" {
    try t(true, &[_]Token{.{ .Bool = true }});
    try t(false, &[_]Token{.{ .Bool = false }});
}

//test "comptime_int" {}

//test "comptime_float" {}

test "enum" {
    // enum literal
    {
        try t(.Foo, &[_]Token{.{ .Enum = .{ .name = "", .variant = "Foo" } }});
    }

    // enum
    {
        const Enum = enum {
            Foo,
            Bar,
        };

        try t(Enum.Foo, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Foo" } }});
        try t(Enum.Bar, &[_]Token{.{ .Enum = .{ .name = "Enum", .variant = "Bar" } }});
    }
}

test "float" {
    try t(@as(f16, 0), &[_]Token{.{ .F16 = 0 }});
    try t(@as(f32, 0), &[_]Token{.{ .F32 = 0 }});
    try t(@as(f64, 0), &[_]Token{.{ .F64 = 0 }});
}

test "hash map" {
    var map = std.AutoHashMap(i32, i32).init(std.testing.allocator);
    defer getty.free(std.testing.allocator, map);

    try map.put(1, 2);

    try t(map, &[_]Token{
        .{ .Map = .{ .len = 1 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .MapEnd = .{} },
    });
}

test "integer" {
    // signed
    {
        try t(@as(i8, 0), &[_]Token{.{ .I8 = 0 }});
        try t(@as(i16, 0), &[_]Token{.{ .I16 = 0 }});
        try t(@as(i32, 0), &[_]Token{.{ .I32 = 0 }});
        try t(@as(i64, 0), &[_]Token{.{ .I64 = 0 }});
    }

    // unsigned
    {
        try t(@as(u8, 0), &[_]Token{.{ .U8 = 0 }});
        try t(@as(u16, 0), &[_]Token{.{ .U16 = 0 }});
        try t(@as(u32, 0), &[_]Token{.{ .U32 = 0 }});
        try t(@as(u64, 0), &[_]Token{.{ .U64 = 0 }});
    }
}

test "null" {
    try t(null, &[_]Token{.{ .Null = {} }});
}

test "optional" {
    try t(@as(?i32, null), &[_]Token{.{ .Null = {} }});
    try t(@as(?i32, 0), &[_]Token{ .{ .Some = {} }, .{ .I32 = 0 } });
}

test "slice" {
    try t(&[_]i32{}, &[_]Token{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = .{} },
    });
    try t(&[_]i32{ 1, 2, 3 }, &[_]Token{
        .{ .Seq = .{ .len = 3 } },
        .{ .I32 = 1 },
        .{ .I32 = 2 },
        .{ .I32 = 3 },
        .{ .SeqEnd = .{} },
    });
}

test "string" {
    try t("abc", &[_]Token{.{ .String = "abc" }});
    try t(&[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
    try t(&[_:0]u8{ 'a', 'b', 'c' }, &[_]Token{.{ .String = "abc" }});
}

test "void" {
    try t({}, &[_]Token{.{ .Void = {} }});
}

fn t(v: anytype, tokens: []const Token) !void {
    var s = Serializer.init(tokens);

    getty.serialize(v, s.serializer()) catch return error.TestUnexpectedError;
    try std.testing.expect(s.remaining() == 0);
}
