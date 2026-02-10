const String = @import("types.zig").String;
const std = @import("std");

pub const TokenType = enum {
    Let,
    Const,
    Function,
    Return,
    True,
    False,
    Null,
    Undefined,

    Identifier,
    Number,
    String,

    Equal,
    Plus,
    Minus,
    Star,
    Slash,

    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Comma,
    Semicolon,
    Period,

    EOF,
    Invalid,
};

pub const Token = struct {
    token_type: TokenType,
    lexeme: String,
    line: usize,
};

pub const Scanner = struct {
    source: String,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    pub fn init(source: String) Scanner {
        return Scanner{ .source = source };
    }

    pub fn scanToken(self: *Scanner) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd()) return self.makeToken(.EOF);

        const c = self.advance();

        if (isAlpha(c)) return self.identifier();
        if (isDigit(c)) return self.number();

        return switch (c) {
            '(' => self.makeToken(.LeftParen),
            ')' => self.makeToken(.RightParen),
            '{' => self.makeToken(.LeftBrace),
            '}' => self.makeToken(.RightBrace),
            ';' => self.makeToken(.Semicolon),
            ',' => self.makeToken(.Comma),
            '.' => self.makeToken(.Period),
            '+' => self.makeToken(.Plus),
            '-' => self.makeToken(.Minus),
            '*' => self.makeToken(.Star),
            '/' => self.makeToken(.Slash),
            '=' => self.makeToken(.Equal),
            '"' => self.string(),
            else => self.makeToken(.Invalid),
        };
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn makeToken(self: Scanner, t_type: TokenType) Token {
        return Token{
            .token_type = t_type,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
        };
    }

    fn isAlpha(c: u8) bool {
        return std.ascii.isAlphabetic(c) or c == '_';
    }

    fn isDigit(c: u8) bool {
        return std.ascii.isDigit(c);
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    fn identifier(self: *Scanner) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();

        const text = self.source[self.start..self.current];
        const t_type: TokenType = if (std.mem.eql(u8, text, "let"))
            .Let
        else if (std.mem.eql(u8, text, "function"))
            .Function
        else if (std.mem.eql(u8, text, "return"))
            .Return
        else
            .Identifier;
        return self.makeToken(t_type);
    }

    fn string(self: *Scanner) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }
        _ = self.advance();
        return self.makeToken(.String);
    }

    fn number(self: *Scanner) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }
        return self.makeToken(.Number);
    }

    fn skipWhitespace(self: *Scanner) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) _ = self.advance();
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }
};
