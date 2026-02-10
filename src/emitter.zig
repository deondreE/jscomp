const std = @import("std");
const ast = @import("ast.zig");

pub const Emitter = struct {
    output: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    var_offset: std.StringHashMap(i32),
    stack_offset: i32,

    pub fn init(allocator: std.mem.Allocator) Emitter {
        return Emitter{
            .output = .empty,
            .allocator = allocator,
            .var_offset = std.StringHashMap(i32).init(allocator),
            .stack_offset = 0,
        };
    }

    pub fn deinit(self: *Emitter) void {
        self.output.deinit(self.allocator);
        self.var_offset.deinit();
    }

    pub fn emit(self: *Emitter, root_nodes: []*ast.Node) ![]const u8 {
        const writer = self.output.writer(self.allocator);

        // Assembly header
        try writer.writeAll(
            \\section .data
            \\    fmt_num db "%ld", 10, 0
            \\
            \\section .text
            \\    global _start
            \\    extern printf
            \\    extern exit
            \\
            \\_start:
            \\    push rbp
            \\    mov rbp, rsp
            \\
        );

        // Emit each statement
        for (root_nodes) |node| {
            try self.emitNode(node);
        }

        // Exit program
        try writer.writeAll(
            \\
            \\    ; Exit
            \\    mov rsp, rbp
            \\    pop rbp
            \\    xor rdi, rdi
            \\    call exit
            \\
        );

        return self.output.items;
    }

    fn emitNode(self: *Emitter, node: *ast.Node) !void {
        const writer = self.output.writer(self.allocator);

        switch (node.*) {
            .literal_expr => |lit| {
                if (lit.type == .number) {
                    // Load number into rax
                    try writer.print("    mov rax, {s}\n", .{lit.value});
                }
            },

            .variable_decl => |decl| {
                // Allocate stack space for variable
                self.stack_offset -= 8;
                try self.var_offset.put(decl.name, self.stack_offset);

                try writer.print("    ; let {s}\n", .{decl.name});
                try self.emitNode(decl.initializer);
                try writer.print("    mov [rbp{d}], rax\n", .{self.stack_offset});
            },

            .indentifier_expr => |name| {
                const offset = self.var_offset.get(name) orelse return error.UndefinedVariable;
                try writer.print("    mov rax, [rbp{d}]\n", .{offset});
            },

            .binary_expr => |bin| {
                // Evaluate left side
                try self.emitNode(bin.left);
                try writer.writeAll("    push rax\n");

                // Evaluate right side
                try self.emitNode(bin.right);

                // Pop left into rbx, right is in rax
                try writer.writeAll("    mov rbx, rax\n");
                try writer.writeAll("    pop rax\n");

                // Perform operation
                if (std.mem.eql(u8, bin.operator, "+")) {
                    try writer.writeAll("    add rax, rbx\n");
                } else if (std.mem.eql(u8, bin.operator, "-")) {
                    try writer.writeAll("    sub rax, rbx\n");
                } else if (std.mem.eql(u8, bin.operator, "*")) {
                    try writer.writeAll("    imul rax, rbx\n");
                } else if (std.mem.eql(u8, bin.operator, "/")) {
                    try writer.writeAll("    cqo\n");
                    try writer.writeAll("    idiv rbx\n");
                }
            },

            .call_expr => |call| {
                // Check if it's a print function
                if (call.callee.* == .indentifier_expr) {
                    const func_name = call.callee.indentifier_expr;
                    if (std.mem.eql(u8, func_name, "print")) {
                        // Evaluate argument
                        if (call.arguments.items.len > 0) {
                            try self.emitNode(call.arguments.items[0]);

                            // Call printf
                            try writer.writeAll(
                                \\    mov rsi, rax
                                \\    lea rdi, [rel fmt_num]
                                \\    xor rax, rax
                                \\    call printf
                                \\
                            );
                        }
                    }
                }
            },
        }
    }
};
