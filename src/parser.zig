const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Token = @import("scanner.zig").Token;
const TokenType = @import("scanner.zig").TokenType;
const ast = @import("ast.zig");

const Precedence = enum(u8) {
    none,
    assignment,
    term,
    factor,
    unary,
    call,
    primary,
};

pub const Parser = struct {
    scanner: *Scanner,
    current: Token,
    previous: Token,
    allocator: std.mem.Allocator,
    had_error: bool = false,

    pub fn init(allocator: std.mem.Allocator, scanner: *Scanner) Parser {
        return Parser{
            .allocator = allocator,
            .scanner = scanner,
            .current = undefined,
            .previous = undefined,
        };
    }

    pub fn advance(self: *Parser) void {
        self.previous = self.current;
        self.current = self.scanner.scanToken();
    }

    fn consume(self: *Parser, t_type: TokenType, message: []const u8) void {
        if (self.current.token_type == t_type) {
            self.advance();
            return;
        }
        std.debug.print("Error at '{s}': {s}\n", .{ self.current.lexeme, message });
        self.had_error = true;
    }

    fn check(self: Parser, t_type: TokenType) bool {
        return self.current.token_type == t_type;
    }

    fn match(self: *Parser, t_type: TokenType) bool {
        if (!self.check(t_type)) return false;
        self.advance();
        return true;
    }

    pub fn parseDeclaration(self: *Parser) !*ast.Node {
        if (self.match(.Let)) {
            return self.variableDeclaration();
        }
        return self.expression();
    }

    fn variableDeclaration(self: *Parser) !*ast.Node {
        self.consume(.Identifier, "Expect variable name.");
        const name = self.previous.lexeme;

        var initializer: *ast.Node = undefined;
        if (self.match(.Equal)) {
            initializer = try self.expression();
        } else {
            return error.TODO;
        }

        self.consume(.Semicolon, "Expected ';' after variable declaration");

        const node = try self.allocator.create(ast.Node);
        node.* = .{ .variable_decl = .{ .name = name, .initializer = initializer } };
        return node;
    }

    fn expression(self: *Parser) !*ast.Node {
        return self.parsePrecedence(.assignment);
    }

    fn parsePrecedence(self: *Parser, precedence: Precedence) error{ OutOfMemory, UnexpectedToken, TODO }!*ast.Node {
        self.advance();

        var left_node = try self.parsePrefix(self.previous.token_type);

        while (@intFromEnum(precedence) <= @intFromEnum(self.getPrecedence(self.current.token_type))) {
            self.advance();
            const operator = self.previous;

            if (operator.token_type == .LeftParen) {
                left_node = try self.finishCall(left_node);
            } else {
                const next_prec = @intFromEnum(self.getPrecedence(operator.token_type)) + 1;
                const right_node = try self.parsePrecedence(@enumFromInt(next_prec));

                const new_node = try self.allocator.create(ast.Node);
                new_node.* = .{
                    .binary_expr = .{
                        .left = left_node,
                        .operator = operator.lexeme,
                        .right = right_node,
                    },
                };
                left_node = new_node;
            }
        }

        return left_node;
    }

    fn finishCall(self: *Parser, callee: *ast.Node) !*ast.Node {
        var arguments = std.ArrayList(*ast.Node){};

        if (!self.check(.RightParen)) {
            while (true) {
                const arg = try self.expression();
                try arguments.append(self.allocator, arg);

                if (!self.match(.Comma)) break;
            }
        }

        self.consume(.RightParen, "Expected ')' after arguments");

        const node = try self.allocator.create(ast.Node);
        node.* = .{
            .call_expr = .{
                .callee = callee,
                .arguments = arguments,
            },
        };
        return node;
    }

    fn getPrecedence(self: Parser, t_type: TokenType) Precedence {
        _ = self;
        return switch (t_type) {
            .LeftParen => .call,
            .Plus, .Minus => .term,
            .Star, .Slash => .factor,
            else => .none,
        };
    }

    fn parsePrefix(self: *Parser, t_type: TokenType) !*ast.Node {
        switch (t_type) {
            .Number => {
                const node = try self.allocator.create(ast.Node);
                node.* = .{ .literal_expr = .{ .value = self.previous.lexeme, .type = .number } };
                return node;
            },
            .Identifier => {
                const node = try self.allocator.create(ast.Node);
                node.* = .{ .indentifier_expr = self.previous.lexeme };
                return node;
            },
            .Minus => {
                const right = try self.parsePrecedence(.unary);
                const node = try self.allocator.create(ast.Node);
                node.* = .{
                    .binary_expr = .{
                        .left = try self.makeZeroLiteral(),
                        .operator = "-",
                        .right = right,
                    },
                };
                return node;
            },
            else => {
                // Better error message
                std.debug.print("Unexpected token: {s} (type: {any})\n", .{ self.previous.lexeme, t_type });
                return error.UnexpectedToken;
            },
        }
    }

    fn makeZeroLiteral(self: *Parser) !*ast.Node {
        const node = try self.allocator.create(ast.Node);
        node.* = .{ .literal_expr = .{ .value = "0", .type = .number } };
        return node;
    }
};
