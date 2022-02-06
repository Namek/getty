const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime LinkedList: type) type {
    return struct {
        allocator: std.mem.Allocator,

        const Self = @This();
        const impl = @"impl Visitor"(LinkedList);

        pub usingnamespace getty.de.Visitor(
            Self,
            impl.visitor.LinkedList,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            impl.visitor.visitSeq,
            undefined,
            undefined,
            undefined,
        );
    };
}

fn @"impl Visitor"(comptime LinkedList: type) type {
    const Self = Visitor(LinkedList);

    return struct {
        pub const visitor = struct {
            pub fn visitSeq(self: Self, comptime Deserializer: type, seq: anytype) Deserializer.Error!LinkedList {
                var list = LinkedList{};
                errdefer getty.de.free(self.allocator, list);

                var current: ?*LinkedList.Node = null;

                while (try seq.nextElement(LinkedList.Node.Data)) |value| {
                    var node = try self.allocator.create(LinkedList.Node);
                    node.* = .{ .data = value };

                    if (current) |c| {
                        c.*.insertAfter(node);
                        current = c.next;
                    } else {
                        list.prepend(node);
                        current = list.first;
                    }
                }

                return list;
            }
        };
    };
}
