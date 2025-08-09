--!strict
--!native
export type SyntaxKind = number -- for hinting

local SyntaxKind = {
  Plus = 0,
  Minus = 1,
  Star = 2,
  Slash = 3,
  Carat = 4,
  Percent = 5,
  Bang = 6,
  Equals = 7,
  EqualsEquals = 8,
  BangEquals = 9,
  PlusEquals = 10,
  MinusEquals = 11,
  StarEquals = 12,
  SlashEquals = 13,
  CaratEquals = 14,
  PercentEquals = 15,
  PlusPlus = 16,
  MinusMinus = 17,
  Question = 18,
  Comma = 19,
  Dot = 20,
  Colon = 21,
  ColonColon = 22,
  Ampersand = 23,
  Pipe = 24,
  LArrow = 25,
  RArrow = 26,
  LParen = 27,
  RParen = 28,
  LBracket = 29,
  RBracket = 30,
  LBrace = 31,
  RBrace = 32,
  LTE = 33,
  GTE = 34,
  Identifier = 35,
  IntLiteral = 36,
  FloatLiteral = 37,
  BoolLiteral = 38,
  StringLiteral = 39,
  LetKeyword = 40
}
table.freeze(SyntaxKind)

type SyntaxName = keyof<typeof(SyntaxKind)>

local SyntaxKindInverse: { [number]: SyntaxName } = {}
for k, v in SyntaxKind :: { [SyntaxName]: SyntaxKind } do
  SyntaxKindInverse[v] = k
end
table.freeze(SyntaxKindInverse)

local keywords = {
  let = SyntaxKind.LetKeyword
} :: { [string]: number }
table.freeze(keywords)

return {
  SyntaxKind = SyntaxKind,
  SyntaxKindInverse = SyntaxKindInverse,
  keywords = keywords
}