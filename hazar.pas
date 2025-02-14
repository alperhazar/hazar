unit hazar; { Hazar(8/16). PRNG based, OTP stream cipher. }

interface

{$define HAZAR8}
//{$define HAZAR16}

const
{$ifdef HAZAR8}
  DataMax = $FF;
  DataHalf = $7F;
{$endif}
{$ifdef HAZAR16}
  DataMax = $FFFF;
  DataHalf = $7FFF;
{$endif}

type
  {$ifdef HAZAR8}
  THazarInteger = Byte;
  {$endif}
  {$ifdef HAZAR16}
  THazarInteger = Word;
  {$endif}

  THazarData = array [$00..DataMax] of THazarInteger;
  THazar = class
    private
      FKey: THazarData;
      FSBox: array [$00..$01, $00..DataMax] of THazarInteger;
      procedure GenerateOTP();
    public
      constructor Initialize(Key: THazarData; KeyLength: THazarInteger);
      procedure ApplyOTP(var Data: THazarData);
  end;

implementation

procedure THazar.GenerateOTP();
var
  I, J, A, B: THazarInteger;
begin
  for I := $00 to $01 do
  begin
    for J := $00 to DataHalf do
    begin
      A := FSBox[I, FKey[J]];
      B := FSBox[I, FKey[J+DataHalf]];
      FSBox[I, FKey[J]] := B;
      FSBox[I, FKey[J+DataHalf]] := A;
    end;
    for J := $00 to DataMax do
      FKey[J] := FSBox[$00, J] xor FSBox[$01, FKey[J]];
  end;
end;

constructor THazar.Initialize(Key: THazarData; KeyLength: THazarInteger);
var
  I, J: THazarInteger;
begin
  inherited Create();
  FKey := Key;
  for I := $00 to $01 do
    for J := $00 to DataMax do
      FSBox[I, J] := I xor J xor KeyLength;
  for I := $00 to KeyLength do
    GenerateOTP();
  for I := $00 to DataMax do
    GenerateOTP();
end;

procedure THazar.ApplyOTP(var Data: THazarData);
var
  I: THazarInteger;
begin
  GenerateOTP();
  for I := $00 to DataMax do
    Data[I] := Data[I] xor FKey[I];
end;

end.
