unit tuz;

interface

const
  SBoxA: array [$0..$F] of Byte = ($5, $8, $1, $D, $A, $3, $4, $2, $E, $F, $C, $7, $6, $0, $9, $B);
  SBoxB: array [$0..$F] of Byte = ($7, $D, $A, $1, $0, $8, $9, $F, $4, $E, $6, $C, $B, $2, $5, $3);

type
  TTuzData = array [$00..$FF] of Byte;
  TTuz = class
    private
      FHash: TTuzData;
      function SBox(Data: Byte): Byte;
    public
      constructor Init();
      procedure Feed(Data: TTuzData; Length: Byte);
      function GetTuzHash(): TTuzData;
  end;

implementation

function TTuz.SBox(Data: Byte): Byte;
begin
  Result := (SBoxA[Data shr $4] shl $4) or (SBoxB[Data and $F]);
  Result := (((Result and $01) shl $07) or (Result shr $01));
end;

constructor TTuz.Init();
begin
  inherited Create();
  FillChar(FHash, SizeOf(FHash), $00);
end;

procedure TTuz.Feed(Data: TTuzData; Length: Byte);
var
  I, J: Byte;
begin
  for I := $00 to Length do
    FHash[I] := FHash[I] xor Data[I];
  for I := $00 to High(FHash) do
  begin
    for J := $00 to High(FHash) - $01 do
      FHash[J+$01] := SBox((FHash[J] xor FHash[J+$01]));
    FHash[$00] := SBox((not (FHash[High(FHash)] xor FHash[$00])));
  end;
end;

function TTuz.GetTuzHash(): TTuzData;
begin
  Result := FHash;
end;

end.
