unit hazarh; { Hash algorithm based on Hazar algorithm(variant) }

interface

uses
  hazar;

type
  THazarH = class(THazar) { This algorithm depends on Hazar8 or Hazar64 while build. }
    private               { HAZAR8 or HAZAR64 compiler directives must be defined at }
      FHash: THazarData;  { main hazar.pas file/unit. }
    public
      constructor Start(Seed: THazarData; Length: THazarInteger);
      function Feed(Seed: THazarData): THazarData;
  end;

implementation

constructor THazarH.Start(Seed: THazarData; Length: THazarInteger);
var
  I: THazarInteger;
begin
  inherited Initialize(Seed, Length);
  for I := $00 to Length do
    FHash[I] := I;
end;

function THazarH.Feed(Seed: THazarData): THazarData;
var
  I: THazarInteger;
begin
  for I := $00 to High(Seed) do
    FHash[I] := FHash[I] xor Seed[I];
  ApplyOTP(FHash);
  Result := FHash;
end;

end.
