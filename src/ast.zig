const std = @import("std");
const String = @import("types.zig").String;

pub const NodeType = enum {
    variable_decl,
    binary_expr,
    literal_expr,
    indentifier_expr,
    call_expr,
    // print_stmt,
};

pub const Node = union(NodeType) {
    variable_decl: struct {
        name: String,
        initializer: *Node,
    },
    binary_expr: struct {
        left: *Node,
        operator: String,
        right: *Node,
    },
    literal_expr: struct {
        value: String,
        type: enum { number, string, boolean },
    },
    indentifier_expr: String,
    call_expr: struct {
        callee: *Node,
        arguments: std.ArrayList(*Node),
    },
};
